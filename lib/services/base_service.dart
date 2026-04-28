import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:thisjowi/services/api_client.dart';
import 'package:thisjowi/services/token_manager.dart';

/// Clase base abstracta para todos los servicios
/// Proporciona funcionalidad comun: HTTP, tokens, logging, manejo de errores
abstract class BaseService {
  final Logger _logger;
  final ApiClient _apiClient = ApiClient();
  final TokenManager _tokenManager = TokenManager();

  BaseService(String serviceName) : _logger = Logger(serviceName);

  /// Cliente HTTP
  ApiClient get apiClient => _apiClient;

  /// Token Manager
  TokenManager get tokenManager => _tokenManager;

  /// Logger
  Logger get logger => _logger;

  /// Log de informacion
  void logInfo(String message) {
    _logger.info(message);
    if (kDebugMode) {
      debugPrint('[INFO] ${_logger.name}: $message');
    }
  }

  /// Log de advertencia
  void logWarning(String message, [dynamic error]) {
    _logger.warning(message, error);
    if (kDebugMode) {
      debugPrint('[WARNING] ${_logger.name}: $message');
      if (error != null) debugPrint('Error: $error');
    }
  }

  /// Log de error
  void logError(String message, dynamic error, StackTrace stackTrace) {
    _logger.severe(message, error, stackTrace);
    if (kDebugMode) {
      debugPrint('[ERROR] ${_logger.name}: $message');
      debugPrint('Error: $error');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  /// Log de debug
  void logDebug(String message) {
    _logger.fine(message);
    if (kDebugMode) {
      debugPrint('[DEBUG] ${_logger.name}: $message');
    }
  }

  /// Valida una respuesta HTTP y lanza excepciones apropiadas
  /// Debe ser implementado por cada servicio con sus excepciones especificas
  void validateResponse(http.Response response);

  /// Parsea el body JSON de una respuesta
  Map<String, dynamic> parseJsonBody(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      logError('Failed to parse JSON response', e, StackTrace.current);
      throw Exception('Invalid JSON response from server');
    }
  }

  /// Parsea el body JSON de una respuesta como lista
  List<dynamic> parseJsonListBody(http.Response response) {
    try {
      return jsonDecode(response.body) as List<dynamic>;
    } catch (e) {
      logError('Failed to parse JSON list response', e, StackTrace.current);
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
          rethrow;
        }
        logWarning('Attempt $attempts failed, retrying in ${delay.inSeconds}s...', e);
        await Future.delayed(delay * attempts);
      }
    }
    throw Exception('Max retries exceeded');
  }
}
