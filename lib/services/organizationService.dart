import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../data/models/organization.dart';

class OrganizationService {
  String get baseUrl => ApiConfig.authUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Get organization by domain
  Future<Map<String, dynamic>> getOrganizationByDomain(String domain) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/organizations/$domain'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'data': Organization.fromJson(data),
        };
      } else {
        return {
          'success': false,
          'message': 'Organization not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Update organization
  Future<Map<String, dynamic>> updateOrganization(
      String orgId, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/organizations/$orgId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(data),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': Organization.fromJson(body)};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to update organization',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Test LDAP Connection
  Future<Map<String, dynamic>> testLdapConnection({
    required String ldapUrl,
    required String ldapBaseDn,
    String? ldapBindDn,
    String? ldapBindPassword,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/organizations/test-connection'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'ldapUrl': ldapUrl,
              'ldapBaseDn': ldapBaseDn,
              'ldapBindDn': ldapBindDn,
              'ldapBindPassword': ldapBindPassword,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'message': body['message']};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Connection failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
