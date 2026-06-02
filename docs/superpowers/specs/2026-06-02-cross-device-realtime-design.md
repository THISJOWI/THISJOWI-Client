# Cross-Device Realtime Sync — Design Document

**Date:** 2026-06-02  
**Scope:** Make the entire THISJOWI app (passwords, notes, OTP, messages) cross-device and realtime  
**Approach:** SSE Gateway in `core` + Kafka events from `cloud` + Flutter SSE client

---

## 1. Objective

When a user creates, edits, or deletes a password, note, or OTP on one device, the change must appear **instantly** on all other devices of the same user. The current request-response HTTP model with 3s polling must be replaced with server-initiated push.

**Non-goals:**
- Multi-user collaboration (not required at this time)
- Offline creation (user must be online to make changes)

---

## 2. Architecture Overview

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Dispositivo1 │  │ Dispositivo2 │  │ Dispositivo3 │
│ (Flutter)    │  │ (Flutter)    │  │ (Flutter)    │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │ SSE (unidirectional)
                   ┌─────┴──────┐
                   │  Sync Hub  │
                   │ (NestJS)   │←─── core repo (centralized, reusable)
                   │ GET /v1/   │      by multiple apps
                   │  sync/     │
                   │  events    │
                   └─────┬──────┘
                         │ consumes Kafka
       ┌─────────────────┼─────────────────┐
       │                 │                 │
  ┌────┴────┐      ┌────┴────┐      ┌────┴────┐
  │ Password│      │  Notes  │      │   OTP   │
  │ Service │      │ Service │      │ Service │
  └────┬────┘      └────┬────┘      └────┬────┘
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │ publishes
                   ┌─────┴──────┐
                   │   Kafka    │
                   │ sync-events│
                   └────────────┘
```

### Why SSE instead of WebSocket?

| Factor | SSE | WebSocket |
|--------|-----|-----------|
| Protocol | HTTP standard | Custom protocol |
| Auth | Standard `Authorization` header | Handshake / message-level |
| Reconnection | Built-in (auto-retry) | Must implement manually |
| Multiplexing | Needs multiple streams | Single bidirectional |
| Backend cost in Java | High (1 thread per stream) | High (1 thread per conn) |

For a password manager where the push is **unidirectional** (server → client), SSE is simpler. The backend complexity is solved by placing the gateway in **NestJS** (Node event loop), not in Java Spring Boot.

### Why NestJS in `core`?

- `core` is the centralized auth / account / profile backend
- A sync hub in `core` is **reusable by multiple apps** (not just THISJOWI)
- NestJS handles thousands of concurrent SSE connections efficiently via the event loop
- The existing `cloud` Java services stay focused on their domains

---

## 3. Sync Hub (NestJS Service in `core`)

### 3.1 Responsibilities

1. Maintain SSE connections from Flutter clients
2. Authenticate each connection via JWT Bearer token
3. Subscribe to Kafka topic `sync-events`
4. Route incoming events to all SSE streams belonging to the target `userId`

### 3.2 Internal Modules

```
sync-hub/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── sse/
│   │   ├── sse.controller.ts          # GET /v1/sync/events
│   │   ├── sse.service.ts             # SessionManager + broadcast
│   │   ├── sse.guard.ts               # JWT validation
│   │   └── sse.interface.ts           # types
│   ├── kafka/
│   │   ├── kafka.module.ts
│   │   ├── kafka.consumer.ts          # listens to sync-events
│   │   └── kafka.config.ts
│   └── redis/
│       ├── redis.module.ts            # multi-instance pub/sub
│       └── redis.service.ts
├── Dockerfile
├── nest-cli.json
├── package.json
└── tsconfig.json
```

### 3.3 SSE Endpoint

```
GET /v1/sync/events
Authorization: Bearer <jwt>
```

**Behavior:**
1. Extract and validate JWT
2. Extract `userId` from the `sub` claim
3. Add the `SseStream` to `SessionManager[userId]`
4. Keep the HTTP connection open
5. On client disconnect → remove the stream from the session map
6. Emit heartbeat events every 30 seconds to keep proxies happy

### 3.4 SessionManager

```typescript
interface SessionManager {
  // Map<userId, Set<ServerSentEventStream>>
  sessions: Map<string, Set<SseStream>>;

  register(userId: string, stream: SseStream): void;
  unregister(userId: string, stream: SseStream): void;
  broadcast(userId: string, event: SyncEvent): void;  // emits to ALL streams of userId
}
```

A single user may have multiple devices connected. Every event is broadcast to **all streams** of that `userId`.

### 3.5 Kafka Consumer

```typescript
@Injectable()
class SyncEventConsumer {
  @MessagePattern('sync-events')
  async handleSyncEvent(payload: KafkaSyncEvent) {
    // payload.userId → find streams → broadcast
    this.sessionManager.broadcast(payload.userId, payload);
  }
}
```

**Kafka consumer group:** `sync-hub-core`  
**Topic:** `sync-events`  
**Offset reset:** `latest` (only new events, no historical replay on connect)

### 3.6 Heartbeat & Reconnection

- Sync Hub emits: `event: heartbeat\ndata: {"ts":1717000000}\n\n` every 30s
- Client closes the stream after 45s without heartbeat → triggers reconnection
- Reconnection uses exponential backoff: 1s → 2s → 4s → 8s → max 30s

---

## 4. Kafka Event Contract

### 4.1 Topic

```
Name:       sync-events
Partitions: 6 (partition key = userId)
Retention:  24 hours
Purpose:    Inter-service broadcast of data mutations to user devices
```

### 4.2 Event Schema

```json
{
  "$id": "https://thisjowi.com/schemas/sync-event.json",
  "type": "object",
  "required": ["eventId", "userId", "serviceName", "action", "payload", "timestamp"],
  "properties": {
    "eventId":      { "type": "string", "description": "UUID v4 del evento" },
    "userId":       { "type": "string", "description": "userId del claim 'sub' del JWT" },
    "serviceName":  { "enum": ["password", "note", "otp", "message"] },
    "action":       { "enum": ["created", "updated", "deleted"] },
    "payload":      {
      "type": "object",
      "description": "Objeto con los campos relevantes. No incluye contenido sensible completo"
    },
    "timestamp":    { "type": "integer", "description": "Epoch millis UTC" }
  }
}
```

### 4.3 Payload Guidelines (per service)

| serviceName | payload fields |
|-------------|---------------|
| `password` | `{ id, title, website, updatedAt }` |
| `note` | `{ id, title, version, updatedAt }` |
| `otp` | `{ id, issuer, label, updatedAt }` |
| `message` | `{ conversationId, messageId, senderId, createdAt }` |

**Principle:** The payload contains enough metadata to update the UI. Full content is **not** sent over Kafka — the client already has it if it authored the change, or fetches via REST if needed.

### 4.4 Producer Code (Java — per service)

```java
// A new SyncEventPublisher.java in each cloud service
@Service
public class SyncEventPublisher {
    private final KafkaTemplate<String, SyncEvent> kafka;

    public SyncEventPublisher(KafkaTemplate<String, SyncEvent> kafka) {
        this.kafka = kafka;
    }

    public void publish(String userId, String action, Object payload) {
        SyncEvent event = SyncEvent.builder()
            .eventId(UUID.randomUUID().toString())
            .userId(userId)
            .serviceName("password") // fixed per service
            .action(action)
            .payload(payload)
            .timestamp(Instant.now().toEpochMilli())
            .build();

        kafka.send("sync-events", userId, event);
    }
}
```

Add one call per CRUD operation in the controller:
```java
@PutMapping("/{id}")
public ResponseEntity<Password> update(...) {
    Password saved = service.save(entry);
    syncEventPublisher.publish(userId, "updated", saved.toDto());
    return ResponseEntity.ok(saved);
}
```

---

## 5. Changes in Cloud Services

| Service | Files added | Lines of code |
|---------|------------|---------------|
| `cloud/password` | `SyncEventPublisher.java`, `SyncEvent.java` | ~40 |
| `cloud/notes` | `SyncEventPublisher.java`, `SyncEvent.java` | ~40 |
| `cloud/otp` | `SyncEventPublisher.java`, `SyncEvent.java` | ~40 |
| `cloud/messages` (NestJS) | `SyncEventPublisher.ts` | ~20 |

**No structural changes** — each service remains a standard Spring Boot / NestJS app. The only addition is publishing a lightweight event to Kafka after every successful mutation.

---

## 6. Client Flutter Changes

### 6.1 New Files

| File | Responsibility |
|------|-------------|
| `lib/services/sync_service.dart` | SSE client: connect, parse, heartbeat, reconnect |
| `lib/core/providers/sync_provider.dart` | State management: start/stop connection, dispatch events |
| `lib/data/models/sync_event.dart` | DTO for incoming SSE events |

### 6.2 SyncService

- Uses `dart:io HttpClient` (mobile/desktop) or `dart:html EventSource` (web)
- Opens SSE connection to `GET https://api.thisjowi.com/v1/sync/events` (path TBD — must match Traefik ingress route)
- Parses incoming `event:` lines, deserializes to `SyncEvent`
- Emits to a `StreamController<SyncEvent>`
- On disconnect → exponential backoff → reconnect with fresh JWT

### 6.3 SyncProvider

```dart
class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;
  StreamSubscription? _sub;
  bool _connected = false;

  Future<void> start() async {
    _sub = _syncService.connect().listen(_onEvent);
    _connected = true;
    notifyListeners();
  }

  void _onEvent(SyncEvent event) {
    switch (event.serviceName) {
      case 'password': _dispatchToPasswords(event);
      case 'note':     _dispatchToNotes(event);
      case 'otp':      _dispatchToOtp(event);
      case 'message':  _dispatchToMessages(event);
    }
  }

  void stop() { _sub?.cancel(); _connected = false; notifyListeners(); }
}
```

### 6.4 Lifecycle

| App state | Behavior |
|-----------|----------|
| Login | `SyncProvider.start()` opens SSE |
| Foreground | Keep SSE open, process events |
| Background | Close SSE (battery), reconnect on foreground |
| Logout | `SyncProvider.stop()`, clear streams |
| Network change | Auto-detect via `connectivity_plus` → reconnect |

### 6.5 Removed / Replaced

| Before | After |
|--------|-------|
| `Timer.periodic(3s)` in `ChatScreen` | SSE push (instant) |
| Pull-to-refresh manual on Password/Notes/OTP | Auto-update via SyncProvider |
| `SyncQueueDao` + manual sync logic | REST write + SSE notification |

---

## 7. Security Considerations

### 7.1 Authentication

- SSE endpoint validates JWT on every connection (`Authorization: Bearer`)
- JWT extracted from standard HTTP header — no custom handshake protocol
- If JWT expires mid-stream, the Sync Hub sends a close event and the client refreshes the token (via existing `TokenManager`) before reconnecting

### 7.2 Authorization

- Events are filtered by `userId` (extracted from JWT `sub` claim)
- A client can **only** receive events for its own `userId`
- No cross-user leakage possible at the Sync Hub layer (Kafka events contain `userId`)

### 7.3 Data on the wire

- SSE events contain **metadata only** (IDs, titles, timestamps)
- Sensitive content (passwords, note content, OTP secrets) is **not** sent over Kafka or SSE
- Full content remains encrypted at rest and fetched via authenticated REST when needed

### 7.4 Transport

- SSE over HTTPS (`wss://` equivalent — just `https://` with `Accept: text/event-stream`)
- TLS 1.3 termination at Traefik ingress

---

## 8. Edge Cases

### 8.1 Concurrent edits on two devices

**Scenario:** User edits the same password title on mobile and desktop simultaneously.

**Resolution:** Last-write-wins at the server. Both changes generate `sync-events`. All devices receive both events in order. The Drift DB ends up with the latest server state.

**Why this is sufficient:** Single-user scenario. No need for CRDTs or merge conflict UI.

### 8.2 Client offline during a burst of changes

**Scenario:** Client disconnects for 2 hours, 50 changes happen.

**Resolution:**
1. On reconnect, client opens SSE (receives no historical data — offset = latest)
2. Client performs a **full sync** via REST: `GET /v1/passwords?since=<lastSyncAt>`
3. Server returns all changes since the given timestamp
4. Client merges into Drift DB, then continues with live SSE events

### 8.3 Sync Hub crashes

**Scenario:** The NestJS pod crashes and restarts.

**Resolution:**
- All client SSE connections drop
- Clients detect disconnect → exponential backoff → reconnect
- Sync Hub starts with empty `SessionManager`, consumers resume from last Kafka offset
- No data loss: Kafka retains 24h, consumers resume where they left off

### 8.4 Multiple Sync Hub instances (horizontal scaling)

**Scenario:** 3 pods of Sync Hub are running behind a load balancer.

**Resolution:**
- Without Redis: events may not reach all user devices if the load balancer sends them to different pods
- **With Redis Pub/Sub:**
  - Each pod subscribes to a Redis channel `sync-events:<userId>`
  - When a Kafka event is consumed, the pod publishes to Redis
  - All pods receive the Redis message and broadcast to their local streams
- **Recommended:** Implement Redis Pub/Sub from day 1 for multi-instance readiness.

---

## 9. Deployment Plan

### 9.1 Infrastructure Prerequisites

| Item | Status | Action |
|------|--------|--------|
| Kafka topic `sync-events` | Needs creation | Run `kafka-topics.sh --create --topic sync-events --partitions 6 --replication-factor 3` |
| K8s namespace for `core` | Already exists | Add Sync Hub deployment to existing manifests |
| Redis in `core` | May need upgrade | Ensure Redis cluster has pub/sub enabled |

### 9.2 Build & Deploy

1. **Phase 1: Kafka topic** — create `sync-events` in production Kafka
2. **Phase 2: Cloud services** — add `SyncEventPublisher` to password, notes, OTP, messages
3. **Phase 3: Sync Hub** — deploy NestJS service to `core` K8s cluster
4. **Phase 4: Flutter client** — implement `SyncService`, `SyncProvider`, remove polling
5. **Phase 5: Traefik route** — add `sync.api.thisjowi.com` → Sync Hub service
6. **Phase 6: Monitoring** — add Grafana dashboards for SSE connections, Kafka lag, reconnection rate

### 9.3 Rollback

- **Sync Hub:** Kubernetes rollback to previous deployment revision
- **Cloud services:** Remove `@EventListener` / `syncEventPublisher.publish(...)` calls
- **Flutter client:** Re-enable `Timer.periodic` fallback (kept behind a feature flag)

---

## 10. Metrics & Monitoring

| Metric | Tool | Alert Threshold |
|--------|------|-----------------|
| SSE connections per userId | NestJS Prometheus | — |
| Kafka consumer lag | Kafka JMX | > 1000 messages |
| Client reconnection rate | Flutter logs + Sentry | > 10/min per device |
| SSE stream lifetime | NestJS logs | < 5s (short connections indicate issues) |

---

## 11. Open Questions (resolved)

| Question | Decision |
|----------|----------|
| Scope of cross-device | Same user, multiple devices only |
| Realtime level | Server-initiated push (SSE), not full CRDT |
| Offline support | Online-first; no offline creation |
| Backend for Sync Hub | NestJS in `core` (centralized, reusable) |
| Protocol | SSE (unidirectional), not WebSocket |
| Conflict resolution | Last-write-wins |
| Data in events | Metadata only (no sensitive content) |
| Multi-instance Sync Hub | Redis Pub/Sub for broadcasting |

---

## 12. Glossary

| Term | Meaning |
|------|---------|
| SSE | Server-Sent Events — HTTP streaming standard for server→client push |
| Sync Hub | NestJS service in `core` that manages SSE streams and consumes Kafka |
| `sync-events` | Kafka topic carrying mutation notifications from cloud services |
| SessionManager | In-memory map `userId → Set<SseStream>` inside Sync Hub |
| LWW | Last-write-wins conflict resolution strategy |

---

*End of design document.*
