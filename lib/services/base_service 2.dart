import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:thisjowi/services/api_client.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/utils/app_logger.dart';

/// Clase base abstracta para todos los servicios
/// Proporciona funcionalidad comun: HTTP, tokens, logging, manejo de errores
abstract class BaseService {
  final AppLogger _logger;
  final ApiClient _apiClient = ApiClient();
  final TokenManager _tokenManager = TokenManager();

  BaseService(String serviceName) : _logger = AppLogger(serviceName);

  /// Cliente HTTP
  ApiClient get apiClient => _apiClient;

  /// Token Manager
  TokenManager get tokenManager => _tokenManager;

  /// Logger
  AppLogger get logger => _logger;

  /// Log de informacion
  void logInfo(String message, {Map<String, dynamic>? context}) {
    _logger.i(message, context: context);
  }

  /// Log de advertencia
  void logWarning(String message, {dynamic error, Map<String, dynamic>? context}) {
    _logger.w(message, error: error, context: context);
  }

  /// Log de error
  void logError(String message, dynamic error, StackTrace stackTrace,
      {Map<String, dynamic>? context}) {
    _logger.e(message, error: error, stackTrace: stackTrace, context: context);
  }

  /// Log de debug
  void logDebug(String message, {Map<String, dynamic>? context}) {
    _logger.d(message, context: context);
  }

  /// Log de verbose (muy detallado)
  void logVerbose(String message, {Map<String, dynamic>? context}) {
    _logger.v(message, context: context);
  }

  /// Valida una respuesta HTTP y lanza excepciones apropiadas
  /// Debe ser implementado por cada servicio con sus excepciones especificas
  void validateResponse(http.Response response);

  /// Parsea el body JSON de una respuesta
  Map<String, dynamic> parseJsonBody(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      logError(
        'Failed to parse JSON response',
        e,
        stackTrace,
        context: {'responseBody': response.body},
      );
      throw Exception('Invalid JSON response from server');
    }
  }

  /// Parsea el body JSON de una respuesta como lista
  List<dynamic> parseJsonListBody(http.Response response) {
    try {
      return jsonDecode(response.body) as List<dynamic>;
    } catch (e, stackTrace) {
      logError(
        'Failed to parse JSON list response',
        e,
        stackTrace,
        context: {'responseBody': response.body},
      );
      throw Exception('Invalid JSON list response from server');
    }
  }

  /// Obtiene el mensaje de error del body de la respuesta
  String extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message'] ?? body['error'] ?? 'Unknown error';
    } catch (e) {
      return response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}';
    }
  }

  /// Verifica si hay conexion a internet
  /// Nota: Esto es un placeholder, deberia usar connectivity_plus
  Future<bool> isOnline() async {
    // Por defecto asumimos online, el ApiClient manejara los errores de red
    return true;
  }

  /// Ejecuta una operacion con reintentos
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          logError(
            'Max retries exceeded',
            e,
            StackTrace.current,
            context: {'attempts': attempts, 'maxRetries': maxRetries},
          );
          rethrow;
        }
        logWarning(
          'Attempt $attempts failed, retrying in ${delay.inSeconds}s...',
          error: e,
          context: {'attempt': attempts, 'maxRetries': maxRetries},
        );
        await Future.delayed(delay * attempts);
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// Log de una peticion HTTP
  void logHttpRequest(String method, String url,
      {Map<String, dynamic>? headers, Map<String, dynamic>? body}) {
    logDebug(
      'HTTP Request: $method $url',
      context: {
        if (headers != null) 'headers': headers,
        if (body != null) 'body': body,
      },
    );
  }

  /// Log de una respuesta HTTP
  void logHttpResponse(int statusCode, String url,
      {Map<String, dynamic>? headers, dynamic body, int? durationMs}) {
    _logger.d(
      'HTTP Response: $statusCode for $url',
      context: {
        'statusCode': statusCode,
        'url': url,
        if (headers != null) 'headers': headers,
        if (body != null) 'body': body,
        if (durationMs != null) 'durationMs': durationMs,
      },
    );
  }
}
