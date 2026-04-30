import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/api.dart';
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

  Future<void> forgotPassword(String email) async {
    await _post('/auth/forgot-password', {'email': email});
  }

  Future<AccountUser?> getCurrentAccount() async {
    final response = await _get('/auth/me');
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return AccountUser.fromJson(json);
    }
    return null;
  }

  Future<void> changePassword(
      String oldPassword, String newPassword, String confirmPassword) async {
    await _post('/auth/change-password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }

  Future<void> deleteAccount(String password) async {
    await _post('/auth/delete-account', {'password': password});
  }
}