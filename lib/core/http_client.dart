import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Improved HTTP client with retry logic, configurable timeouts, and better error handling
/// 
/// This client handles:
/// - Automatic retries with exponential backoff
/// - Configurable timeouts
/// - Connection pooling
/// - Better error messages for debugging
class HttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  
  /// Maximum number of retries for failed requests
  final int maxRetries;
  
  /// Base timeout duration for requests
  final Duration timeout;
  
  /// Initial delay before first retry (grows exponentially)
  final Duration initialRetryDelay;
  
  HttpClient({
    this.maxRetries = 3,
    this.timeout = const Duration(seconds: 60),
    this.initialRetryDelay = const Duration(milliseconds: 500),
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    Duration retryDelay = initialRetryDelay;
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          debugPrint('📡 [HTTP] ${request.method} ${request.url} (Attempt ${attempt + 1}/${maxRetries + 1})');
        }
        
        // Create a fresh copy of the request for each attempt (avoid "Can't finalize a finalized Request" error)
        final requestCopy = _copyRequest(request);
        final response = await _inner.send(requestCopy).timeout(timeout);
        
        // Success - return response
        if (response.statusCode < 500) {
          if (kDebugMode) {
            debugPrint('✅ [HTTP] ${request.method} ${request.url} - Status: ${response.statusCode}');
          }
          return response;
        }
        
        // Server error (5xx) - retry if not last attempt
        if (attempt < maxRetries) {
          if (kDebugMode) {
            debugPrint('⚠️ [HTTP] Server error ${response.statusCode}, retrying in ${retryDelay.inMilliseconds}ms...');
          }
          await Future.delayed(retryDelay);
          retryDelay *= 2; // Exponential backoff
          continue;
        }
        
        return response;
      } on TimeoutException {
        if (kDebugMode) {
          debugPrint('⏱️ [HTTP] Timeout on attempt ${attempt + 1}/${maxRetries + 1}');
        }
        
        if (attempt < maxRetries) {
          if (kDebugMode) {
            debugPrint('🔄 [HTTP] Retrying in ${retryDelay.inMilliseconds}ms...');
          }
          await Future.delayed(retryDelay);
          retryDelay *= 2;
          continue;
        }
        
        rethrow;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ [HTTP] Error: $e');
        }
        
        // For connection errors, retry if not last attempt
        if (attempt < maxRetries && _isRetryable(e)) {
          if (kDebugMode) {
            debugPrint('🔄 [HTTP] Retrying in ${retryDelay.inMilliseconds}ms...');
          }
          await Future.delayed(retryDelay);
          retryDelay *= 2;
          continue;
        }
        
        rethrow;
      }
    }
    
    throw Exception('Failed to complete request after $maxRetries retries');
  }

  /// Create a copy of the request for retrying
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    http.BaseRequest requestCopy;
    
    if (request is http.Request) {
      requestCopy = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      requestCopy = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw Exception('Cannot retry a StreamedRequest');
    } else {
      throw Exception('Unknown request type: ${request.runtimeType}');
    }
    
    requestCopy
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..headers.addAll(request.headers);
    
    return requestCopy;
  }

  /// Determine if an error is retryable
  bool _isRetryable(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    // Connection errors are retryable
    return errorStr.contains('connection') ||
           errorStr.contains('timeout') ||
           errorStr.contains('temporary failure') ||
           errorStr.contains('network') ||
           errorStr.contains('reset by peer') ||
           errorStr.contains('connection refused');
  }
}
