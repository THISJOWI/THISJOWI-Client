import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/data/models/sync_event.dart';
import 'package:thisjowi/services/connectivityService.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/utils/app_logger.dart';

/// Servicio de conexión SSE (Server-Sent Events) para recibir
/// notificaciones de sincronización en tiempo real desde el backend.
///
/// Se conecta al Sync Hub de `core` mediante SSE y emite eventos
/// que el SyncProvider consume para actualizar el estado local.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final TokenManager _tokenManager = TokenManager();
  final ConnectivityService _connectivity = ConnectivityService();

  HttpClient? _httpClient;
  StreamSubscription? _connectivitySub;

  /// Controller de eventos emitidos a los consumidores
  final StreamController<SyncEvent> _eventController =
      StreamController<SyncEvent>.broadcast();

  /// Estado de conexión observable
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<SyncEvent> get events => _eventController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _shouldReconnect = true;
  Timer? _reconnectTimer;

  /// Guard para evitar múltiples conexiones concurrentes
  bool _isConnecting = false;

  /// Contador de reintentos para exponential backoff
  int _retryCount = 0;

  /// Máximo tiempo entre heartbeats antes de considerar desconexión.
  /// Server heartbeat = 15s, so we allow up to 35s (2x + 5s margin).
  static const int heartbeatTimeoutSeconds = 35;

  /// Intervalo base para reconnection backoff
  static const int baseRetryDelaySeconds = 1;

  /// Máximo delay de reconnection backoff
  static const int maxRetryDelaySeconds = 30;

  /// Conecta al stream SSE del Sync Hub
  Future<void> connect() async {
    if (_isConnected) {
      appLog.i('SyncService: already connected, skipping');
      return;
    }

    _shouldReconnect = true;
    _startSseConnection();

    // Escuchar cambios de conectividad para reconectar
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.connectionStatus.listen((isOnline) {
      if (isOnline && !_isConnected && _shouldReconnect) {
        appLog.i('SyncService: network restored, reconnecting');
        _startSseConnection();
      }
    });
  }

  /// Inicia la conexión SSE con el backend
  void _startSseConnection() async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      _httpClient?.close(force: true);

      final token = await _tokenManager.getToken();
      if (token == null || token.isEmpty) {
        appLog.w('SyncService: no token available, delaying connection');
        _scheduleReconnect();
        return;
      }

      final syncUrl = _buildSyncUrl();
      appLog.i('SyncService: connecting to $syncUrl');

      _httpClient = HttpClient();
      _httpClient!.connectionTimeout = const Duration(seconds: 15);
      // No idle timeout for SSE — connection stays open until server closes
      _httpClient!.idleTimeout = Duration.zero;

      final request = await _httpClient!.openUrl('GET', Uri.parse(syncUrl));
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();

      if (response.statusCode == 401) {
        appLog.w('SyncService: 401 Unauthorized - token may have expired');
        _updateConnectionState(false);
        return;
      }

      if (response.statusCode != 200) {
        appLog.w('SyncService: unexpected status ${response.statusCode}');
        _scheduleReconnect();
        return;
      }

      _retryCount = 0;
      appLog.i('SyncService: SSE stream opened (status=${response.statusCode})');
      _updateConnectionState(true);

      String eventName = 'message';
      final dataBuffer = StringBuffer();
      bool receivedFirstEvent = false;

      await for (final line in response
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!_shouldReconnect) break;

        if (line.startsWith('event:')) {
          eventName = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          if (dataBuffer.isNotEmpty) dataBuffer.write('\n');
          dataBuffer.write(line.substring(5).trim());
        } else if (line.isEmpty) {
          if (dataBuffer.isNotEmpty) {
            _processSseEvent(eventName, dataBuffer.toString());
            dataBuffer.clear();
          }
          eventName = 'message';

          if (!receivedFirstEvent) {
            receivedFirstEvent = true;
            appLog.i('SyncService: first SSE event received successfully');
          }
        }
      }

      appLog.i('SyncService: SSE stream closed');
      _updateConnectionState(false);

      if (_shouldReconnect) _scheduleReconnect();
    } on SocketException catch (e) {
      appLog.w('SyncService: network error - ${e.message}');
      _updateConnectionState(false);
      if (_shouldReconnect) _scheduleReconnect();
    } on HttpException catch (e) {
      appLog.w('SyncService: HTTP error - ${e.message}');
      _updateConnectionState(false);
      if (_shouldReconnect) _scheduleReconnect();
    } on StateError catch (e) {
      appLog.w('SyncService: connection closed unexpectedly - ${e.message}');
      _updateConnectionState(false);
      if (_shouldReconnect) _scheduleReconnect();
    } catch (e, st) {
      appLog.e('SyncService: unexpected error', error: e, stackTrace: st);
      _updateConnectionState(false);
      if (_shouldReconnect) _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  /// Procesa un evento SSE individual
  void _processSseEvent(String eventName, String data) {
    if (eventName == 'heartbeat') {
      // Heartbeat recibido, conexión viva
      return;
    }

    if (eventName == 'sync') {
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final event = SyncEvent.fromJson(json);

        appLog.i('SyncService: RECEIVED SSE event=${event.serviceName}/${event.action} userId=${event.userId} eventId=${event.eventId}');

        _eventController.add(event);
      } catch (e, st) {
        appLog.e('SyncService: failed to parse sync event', error: e, stackTrace: st);
      }
      return;
    }

    if (eventName == 'close') {
      appLog.i('SyncService: server requested close');
      _shouldReconnect = false;
      _updateConnectionState(false);
      return;
    }

    // Otros eventos
    appLog.d('SyncService: unhandled event "$eventName"');
  }

  /// Programa una reconexión con backoff exponencial
  void _scheduleReconnect() {
    if (!_shouldReconnect) return;

    _retryCount++;
    // Exponencial con jitter: 1s, 2s, 4s, 8s, 16s, 30s (max)
    int delay = (baseRetryDelaySeconds * (1 << (_retryCount - 1)))
        .clamp(baseRetryDelaySeconds, maxRetryDelaySeconds);
    // Añadir jitter aleatorio (±25%) para evitar thundering herd
    delay += (delay * 0.25 * (Random().nextDouble() * 2 - 1)).round();
    delay = delay.clamp(baseRetryDelaySeconds, maxRetryDelaySeconds);

    appLog.d('SyncService: reconnecting in ${delay}s (attempt #$_retryCount)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (_shouldReconnect && _connectivity.isOnline) {
        _startSseConnection();
      }
    });
  }

  /// Desconecta el stream SSE y cancela reconexiones
  Future<void> disconnect() async {
    appLog.i('SyncService: disconnecting');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _retryCount = 0;
    _isConnecting = false;

    _httpClient?.close(force: true);
    _httpClient = null;

    _updateConnectionState(false);
  }

  /// Cierra todos los recursos (usar al hacer logout)
  Future<void> dispose() async {
    await disconnect();
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
    if (!_connectionController.isClosed) {
      await _connectionController.close();
    }
  }

  /// Construye la URL del endpoint SSE
  String _buildSyncUrl() {
    // Usa la misma base que los servicios REST
    // El endpoint del Sync Hub está en `core` pero expuesto a través del gateway
    final base = ApiConfig.baseUrl;
    return '$base/v1/sync/events';
  }

  void _updateConnectionState(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectionController.add(connected);
    }
  }
}
