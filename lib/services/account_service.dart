import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/exceptions/account_exceptions.dart';
import 'package:thisjowi/data/models/account_user.dart';
import 'package:thisjowi/services/token_manager.dart';

class AccountService {
  final TokenManager _tokenManager = TokenManager();

  Future<http.Response> _get(String endpoint) async {
    final token = await _tokenManager.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    final token = await _tokenManager.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> _delete(String endpoint, Map<String, dynamic> body) async {
    final token = await _tokenManager.getToken();
    final url = '${ApiConfig.baseUrl}$endpoint';
    final bodyJson = jsonEncode(body);
    
    if (kDebugMode) {
      debugPrint('flutter: 🗑️ DELETE $url');
      debugPrint('flutter: 📦 Body: $bodyJson');
      debugPrint('flutter: 🔐 Token: ${token != null ? 'SET' : 'NOT SET'}');
    }
    
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: bodyJson,
    );
    
    if (kDebugMode) {
      debugPrint('flutter: 📥 Response: ${response.statusCode}');
      debugPrint('flutter: 📄 Body: ${response.body}');
    }
    
    return response;
  }

  Future<void> forgotPassword(String email) async {
    await _post('/v1/auth/forgot-password', {'email': email});
  }

  Future<AccountUser?> getCurrentAccount() async {
    final response = await _get('/v1/auth/me');
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return AccountUser.fromJson(json);
    }
    return null;
  }

  Future<void> changePassword(
      String oldPassword, String newPassword, String confirmPassword) async {
    await _post('/v1/auth/change-password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }

  Future<void> deleteAccount(String password) async {
    if (kDebugMode) {
      debugPrint('flutter: Info: deleteAccount() called');
    }

    final response = await _delete('/v1/auth/delete-account', {'password': password});
    
    if (kDebugMode) {
      debugPrint('flutter: Info: deleteAccount response status: ${response.statusCode}');
    }
    
    // Handle different status codes
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (kDebugMode) {
        debugPrint('flutter: Info: Account deleted successfully');
      }
      return;
    }
    
    // Parse error response
    try {
      final json = jsonDecode(response.body);
      final message = json['message'] ?? 'Error al eliminar la cuenta';
      
      if (response.statusCode == 401) {
        throw AccountException(
          message: 'Contraseña incorrecta',
          code: 'INVALID_PASSWORD',
          details: message,
        );
      } else if (response.statusCode == 400) {
        throw AccountException(
          message: message,
          code: 'INVALID_REQUEST',
          details: json,
        );
      } else if (response.statusCode >= 500) {
        throw AccountServerException(
          statusCode: response.statusCode,
          message: message,
          details: json,
        );
      } else {
        throw AccountDeletionException(
          message: message,
          details: json,
        );
      }
    } catch (e) {
      if (e is AccountException) {
        rethrow;
      }
      throw AccountDeletionException(
        message: 'Error al eliminar la cuenta: ${response.statusCode}',
        details: response.body,
      );
    }
  }
}