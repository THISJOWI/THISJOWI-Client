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
      final response = await http
          .post(
            Uri.parse('$baseUrl/ldap/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'domain': domain,
              'username': username,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Timeout al conectarse con servidor LDAP'),
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
      } else {
        return {
          'success': false,
          'message': _parseError(response),
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

  /// Probar conexión LDAP antes de guardar configuración
  Future<Map<String, dynamic>> testLdapConnection(
      Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http
          .post(
            Uri.parse('$baseUrl/ldap/test-connection'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(config),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Timeout al probar conexión LDAP'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Conexión exitosa',
          'configValid': data['configValid'] ?? false,
          'credentialsValid': data['credentialsValid'] ?? false,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'connectionError': data['connectionError'],
          'credentialsError': data['credentialsError'],
          'message': data['message'] ?? 'Error de conexión',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Actualizar configuración LDAP de organización
  Future<Map<String, dynamic>> updateOrganization(
      String orgId, Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http
          .put(
            Uri.parse('$baseUrl/organizations/$orgId'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(config),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Timeout'),
          );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Configuración guardada',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error al guardar',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Sincronizar usuarios LDAP manualmente
  Future<Map<String, dynamic>> syncLdapUsers(String domain) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/ldap/sync/$domain'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Timeout al sincronizar usuarios'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'syncedCount': data['syncedCount'] ?? 0,
          'deactivatedCount': data['deactivatedCount'] ?? 0,
          'foundInLdap': data['foundInLdap'] ?? 0,
          'message': data['message'] ?? 'Sincronización completada',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error al sincronizar',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Obtener estado de sincronización
  Future<Map<String, dynamic>> getSyncStatus(String domain) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/ldap/sync-status/$domain'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

<<<<<<< HEAD
  /// Obtener todos los usuarios LDAP de un dominio
  /// Usado para mostrar contactos disponibles en mensajería
  Future<Map<String, dynamic>> getLdapUsersByDomain(String domain) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/ldap/users/$domain'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout al obtener usuarios'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'users': data['users'] ?? [],
          'count': data['count'] ?? 0,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener usuarios',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Verificar si el usuario actual es LDAP y obtener su dominio
  Future<String?> getCurrentUserDomain() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLdapUser = prefs.getBool('isLdapUser') ?? false;
      final email = prefs.getString('email');
      
      if (isLdapUser && email != null && email.contains('@')) {
        return email.split('@')[1];
      }
      return null;
    } catch (e) {
      return null;
=======
  String _parseError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body != null && body['message'] != null) {
        return body['message'];
      }
    } catch (_) {}

    switch (res.statusCode) {
      case 400:
        return 'Solicitud incorrecta. Por favor, revisa los datos.';
      case 401:
        return 'Credenciales inválidas. Por favor, inténtalo de nuevo.';
      case 403:
        return 'Acceso denegado. No tienes permisos.';
      case 404:
        return 'No se encontró el recurso solicitado.';
      case 409:
        return 'Conflicto. Es posible que el usuario pase por un error de duplicidad.';
      case 500:
        return 'Error interno del servidor. Por favor, inténtalo más tarde.';
      default:
        return 'Error: ${res.statusCode}';
>>>>>>> master
    }
  }
}
