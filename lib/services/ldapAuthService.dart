import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../data/models/user.dart';
import '../data/models/organization.dart';

/// Service para manejar autenticación LDAP
class LdapAuthService {
  String get baseUrl => ApiConfig.authUrl;

  /// Login con LDAP
  /// Domain: ejemplo.com
  /// Username: usuario de LDAP
  /// Password: contraseña de LDAP
  Future<Map<String, dynamic>> loginWithLdap({
    required String domain,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ldap/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'domain': domain,
          'username': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Timeout al conectarse con servidor LDAP'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Guardar token y datos del usuario
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('userId', data['userId'].toString());
          await prefs.setString('email', data['email']);
          await prefs.setString('orgId', data['orgId']);
          await prefs.setString('ldapUsername', data['ldapUsername']);
          await prefs.setBool('isLdapUser', true);

          return {
            'success': true,
            'message': 'Autenticación LDAP exitosa',
            'data': {
              'user': User(
                id: data['userId'].toString(),
                email: data['email'],
                orgId: data['orgId'],
                ldapUsername: data['ldapUsername'],
                isLdapUser: true,
              ),
              'token': data['token'],
            },
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error en autenticación LDAP',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Credenciales de LDAP inválidas',
        };
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Error de conexión con servidor LDAP',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Obtener organización por dominio
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
          'message': 'Organización no encontrada',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Verificar si un dominio tiene LDAP habilitado
  Future<bool> isLdapEnabledForDomain(String domain) async {
    try {
      final response = await getOrganizationByDomain(domain);
      if (response['success'] == true) {
        final org = response['data'] as Organization;
        return org.ldapEnabled && org.isActive;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtener información de usuario LDAP autenticado
  Future<User?> getLdapUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final email = prefs.getString('email');
      final orgId = prefs.getString('orgId');
      final ldapUsername = prefs.getString('ldapUsername');
      final isLdapUser = prefs.getBool('isLdapUser') ?? false;

      if (email != null && isLdapUser) {
        return User(
          id: userId,
          email: email,
          orgId: orgId,
          ldapUsername: ldapUsername,
          isLdapUser: isLdapUser,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Limpiar datos de sesión LDAP
  Future<void> clearLdapSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('orgId');
      await prefs.remove('ldapUsername');
      await prefs.remove('isLdapUser');
    } catch (e) {
      print('Error clearing LDAP session: $e');
    }
  }
}
