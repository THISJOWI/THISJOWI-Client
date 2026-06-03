# Sync-Hub Client Integration — Design Document

**Date:** 2026-06-03
**Scope:** Complete the Flutter client integration with sync-hub (SSE real-time sync) for passwords, notes, OTP, profile, and account data
**Prerequisite:** sync-hub NestJS service in `core/` (already deployed), SSE client in `SyncService` (already built)

---

## 1. Objective

Bridge the gap between the existing SSE infrastructure (SyncService, SyncProvider) and the local data layer so that real-time sync events from sync-hub are actually applied to the local Drift database and reflected in the UI.

---

## 2. What Already Exists

| Component | Status | Location |
|-----------|--------|----------|
| sync-hub (NestJS SSE gateway) | ✅ Deployed in `core/` | `core/sync-hub/` |
| `SyncService` (SSE client) | ✅ Complete | `lib/services/sync_service.dart` |
| `SyncEvent` model | ✅ Complete | `lib/data/models/sync_event.dart` |
| `SyncProvider` (event dispatcher) | ✅ Complete | `lib/core/providers/sync_provider.dart` |
| `OtpRepository` (offline-first CRUD) | ✅ Works, missing 2 methods | `lib/data/repository/otp_repository.dart` |
| `NotesRepository` (offline-first CRUD) | ✅ Works, missing 2 methods | `lib/data/repository/notes_repository.dart` |
| `PasswordsRepository` (offline-first CRUD) | ✅ Works, missing 2 methods | `lib/data/repository/passwordsRepository.dart` |
| `ServiceLocator` | ✅ Singletons for repos | `lib/core/service_locator.dart` |
| Drift database (6 tables) | ✅ Schema v6 | `lib/data/local/database.dart` |
| `LogoutService` | ✅ Sync stop is commented out | `lib/services/logoutService.dart` |

---

## 3. What's Missing

### 3.1 `applyRemoteChange()` in each repository

Called by SyncProvider when an SSE `created` or `updated` event arrives. Must:

1. Extract `serverId` from `payload['id']`
2. Look up local record by `serverId`
3. If exists → update with payload fields + mark `syncStatus = 'synced'`
4. If not exists → fetch full entity from server via REST API, then insert locally

### 3.2 `deleteLocalById()` in each repository

Called by SyncProvider when an SSE `deleted` event arrives. Must:

1. Search local DB by `serverId` (the `id` in payload)
2. Hard delete the record

### 3.3 ProfileRepository

Profile data (avatar, fullName, country, birthDate, preferences, accountType, hostingMode) needs local persistence so it survives offline and can react to sync events.

**New Drift table `Profiles`:**
```
Profiles:
  userId (Text, PK)
  fullName (Text, nullable)
  country (Text, nullable)
  avatarUrl (Text, nullable)
  birthDate (Text, nullable)
  publicKey (Text, nullable)
  preferences (Text, nullable) // JSON string
  accountType (Text, nullable)
  hostingMode (Text, nullable)
  updatedAt (Text, nullable)
```

**New `ProfileDao`**: CRUD operations on Profiles table.

**New `ProfileRepository`**:
- `getProfile()` → load from local DB
- `updateProfile(data)` → save local + sync to server via ProfileService REST
- `applyRemoteChange(payload)` → called by SyncProvider for profile events
- `deleteLocalById(userId)` → called by SyncProvider for profile delete events

### 3.4 SyncProvider lifecycle integration

| Point | Action |
|-------|--------|
| `main.dart` | Register `ChangeNotifierProvider(create: (_) => SyncProvider())` |
| Login | `context.read<SyncProvider>().start()` after successful auth |
| Logout | `SyncProvider().stop()` + clear local profile data |
| App resume | Reconnect SSE |

### 3.5 OtpProvider real-time reaction

- Register `SyncProvider` listener in `OtpProvider` (or use `context.read`)
- On OTP SSE event → silent `loadEntries()`
- Remove `Timer.periodic(3s)` auto-refresh (replaced by SSE push)

### 3.6 Logout cleanup

LogoutService currently comments out sync stop. Update to:
1. `SyncProvider().stop()` (stop SSE connection)
2. Clear all local data (already done)
3. Also clear Profiles table

---

## 4. Files Changed

| File | Change |
|------|--------|
| `lib/data/repository/passwordsRepository.dart` | Add `applyRemoteChange()`, `deleteLocalById()` |
| `lib/data/repository/notes_repository.dart` | Add `applyRemoteChange()`, `deleteLocalById()` |
| `lib/data/repository/otp_repository.dart` | Add `applyRemoteChange()`, `deleteLocalById()` |
| `lib/data/local/database.dart` | Add `Profiles` table, bump schema to v7 |
| `lib/data/local/dao/profile_dao.dart` | New file |
| `lib/data/models/profile_entry.dart` | New model for local profile storage |
| `lib/data/repository/profile_repository.dart` | New file |
| `lib/core/service_locator.dart` | Add `ProfileRepository` |
| `lib/core/providers/sync_provider.dart` | Add profile dispatch logic |
| `lib/core/providers/otp_provider.dart` | Remove auto-refresh timer, react to SSE |
| `lib/main.dart` | Register `SyncProvider` in widget tree |
| `lib/services/logoutService.dart` | Call `SyncProvider().stop()`, clear profiles |

---

## 5. Edge Cases

- **SSE event arrives for item not in local DB**: Repository fetches full entity from server via REST, then inserts locally. If server is unreachable, the event is logged and skipped (next full sync will catch it).
- **Concurrent local edit + remote event**: Last-write-wins. Whichever mutation happens last on the server is the source of truth. Local `syncStatus` is set to `synced` after applying remote changes.
- **Profile update race**: Profile changes are infrequent. If a profile sync event arrives while user edits profile locally, local save + background sync wins (it's a single-user scenario).
- **SSE disconnect + burst of changes**: On reconnect, a full REST sync (`_syncFromServer()`) is triggered which catches any missed events.

---

## 6. Non-Goals

- Multi-user collaboration
- Offline creation of data (user must be online)
- Migrating messages from WebSocket to SSE (stays as-is)
- Refactoring repo pattern into a base class

---

## 7. Data Flow Summary

```
sync-hub (NestJS)
  ↓ SSE event
SyncService (SSE parser)
  ↓ SyncEvent
SyncProvider (dispatcher)
  ↓ by serviceName
PasswordsRepository.applyRemoteChange(payload)
NotesRepository.applyRemoteChange(payload)
OtpRepository.applyRemoteChange(payload)
ProfileRepository.applyRemoteChange(payload)
  ↓
Drift local DB (offline-first)
  ↓ notifyListeners()
UI (OtpProvider / screens auto-refresh)
```

---

*End of design document.*
