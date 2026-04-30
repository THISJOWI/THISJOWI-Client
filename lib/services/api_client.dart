import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/services/token_manager.dart';

/// Cliente HTTP centralizado para todas las llamadas a la API
/// Maneja automáticamente headers, timeouts, tokens y logging
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  final TokenManager _tokenManager = TokenManager();

  /// Timeout por defecto para las peticiones
  Duration get _defaultTimeout => Duration(seconds: ApiConfig.requestTimeout);

  /// Headers base para todas las peticiones
  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Headers con autenticación
  Future<Map<String, String>> get _authHeaders async {
    final token = await _tokenManager.getToken();
    final headers = Map<String, String>.from(_baseHeaders);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Realiza una petición GET
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final requestHeaders = requiresAuth 
        ? await _authHeaders 
        : {..._baseHeaders, ...?headers};
    
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    
    _logRequest('GET', url.toString(), requestHeaders);

    try {
      final response = await _client
          .get(url, headers: requestHeaders)
          .timeout(timeout ?? _defaultTimeout);
      
      _logResponse('GET', url.toString(), response);
      return response;
    } on TimeoutException {
      throw TimeoutException('Request timeout after ${timeout ?? _defaultTimeout}');
    } on SocketException catch (e) {
      throw SocketException('Network error: ${e.message}');
    }
  }

  /// Realiza una petición POST
  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final requestHeaders = requiresAuth 
        ? await _authHeaders 
        : {..._baseHeaders, ...?headers};
    
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final encodedBody = body != null ? jsonEncode(body) : null;
    
    _logRequest('POST', url.toString(), requestHeaders, encodedBody);

    try {
      final response = await _client
          .post(url, headers: requestHeaders, body: encodedBody)
          .timeout(timeout ?? _defaultTimeout);
      
      _logResponse('POST', url.toString(), response);
      return response;
    } on TimeoutException {
      throw TimeoutException('Request timeout after ${timeout ?? _defaultTimeout}');
    } on SocketException catch (e) {
      throw SocketException('Network error: ${e.message}');
    }
  }

  /// Realiza una petición PUT
  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final requestHeaders = requiresAuth 
        ? await _authHeaders 
        : {..._baseHeaders, ...?headers};
    
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final encodedBody = body != null ? jsonEncode(body) : null;
    
    _logRequest('PUT', url.toString(), requestHeaders, encodedBody);

    try {
      final response = await _client
          .put(url, headers: requestHeaders, body: encodedBody)
          .timeout(timeout ?? _defaultTimeout);
      
      _logResponse('PUT', url.toString(), response);
      return response;
    } on TimeoutException {
      throw TimeoutException('Request timeout after ${timeout ?? _defaultTimeout}');
    } on SocketException catch (e) {
      throw SocketException('Network error: ${e.message}');
    }
  }

  /// Realiza una petición DELETE
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final requestHeaders = requiresAuth 
        ? await _authHeaders 
        : {..._baseHeaders, ...?headers};
    
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final encodedBody = body != null ? jsonEncode(body) : null;
    
    _logRequest('DELETE', url.toString(), requestHeaders, encodedBody);

    try {
      final response = await _client
          .delete(url, headers: requestHeaders, body: encodedBody)
          .timeout(timeout ?? _defaultTimeout);
      
      _logResponse('DELETE', url.toString(), response);
      return response;
    } on TimeoutException {
      throw TimeoutException('Request timeout after ${timeout ?? _defaultTimeout}');
    } on SocketException catch (e) {
      throw SocketException('Network error: ${e.message}');
    }
  }

  /// Realiza una petición PATCH
  Future<http.Response> patch(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final requestHeaders = requiresAuth 
        ? await _authHeaders 
        : {..._baseHeaders, ...?headers};
    
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final encodedBody = body != null ? jsonEncode(body) : null;
    
    _logRequest('PATCH', url.toString(), requestHeaders, encodedBody);

    try {
      final response = await _client
          .patch(url, headers: requestHeaders, body: encodedBody)
          .timeout(timeout ?? _defaultTimeout);
      
      _logResponse('PATCH', url.toString(), response);
      return response;
    } on TimeoutException {
      throw TimeoutException('Request timeout after ${timeout ?? _defaultTimeout}');
    } on SocketException catch (e) {
      throw SocketException('Network error: ${e.message}');
    }
  }

  /// Sube un archivo multipart
  Future<http.StreamedResponse> uploadFile(
    String endpoint, {
    required File file,
    required String fieldName,
    Map<String, String>? additionalFields,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final requestHeaders = requiresAuth 
        ? await _authHeaders 
        : _baseHeaders;

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', url);
    
    request.headers.addAll(requestHeaders);
    
    // Agregar archivo
    request.files.add(await http.MultipartFile.fromPath(
      fieldName,
      file.path,
    ));
    
    // Agregar campos adicionales
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }

    _logRequest('MULTIPART', url.toString(), requestHeaders, 'File: ${file.path}');

    try {
      final response = await request.send().timeout(timeout ?? _defaultTimeout);
      _logResponse('MULTIPART', url.toString(), null, 'Status: ${response.statusCode}');
      return response;
    } on TimeoutException {
      throw TimeoutException('Request timeout after ${timeout ?? _defaultTimeout}');
    } on SocketException catch (e) {
      throw SocketException('Network error: ${e.message}');
    }
  }

  /// Logging de requests
  void _logRequest(String method, String url, Map<String, String> headers, [String? body]) {
    if (kDebugMode) {
      debugPrint('📤 $method $url');
    }
  }

  /// Logging de responses
  void _logResponse(String method, String url, http.Response? response, [String? message]) {
    if (kDebugMode) {
      if (response != null) {
        debugPrint('📥 ${response.statusCode} $url');
      } else if (message != null) {
        debugPrint('📥 $message');
      }
    }
  }

  /// Cierra el cliente HTTP
  void dispose() {
    _client.close();
  }
}
