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

      final headers = token != null
          ? {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            }
          : {'Content-Type': 'application/json'};

      final response = await http
          .post(
            Uri.parse('$baseUrl/ldap/test-connection'),
            headers: headers,
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

  /// Registrar nueva organización con LDAP
  Future<Map<String, dynamic>> registerLdapOrganization({
    required String organizationName,
    required String ldapUrl,
    required String adminCn,
    required String dc,
    required String adminPassword,
    String? baseDn,
    required String hostingMode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // 1. Derivar el dominio desde el DC (ej: dc=thisjowi,dc=local -> thisjowi.local)
      String domain = dc
          .split(',')
          .where((part) => part.trim().toLowerCase().startsWith('dc='))
          .map((part) => part.split('=')[1].trim())
          .join('.');

      if (domain.isEmpty) domain = 'unknown.local';

      // Usamos la URL base general ya que los tenants están en /api/v1/tenants
      final String tenantsUrl = '${ApiConfig.baseUrl}/api/v1/tenants';
      final headers = token != null
          ? {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            }
          : {'Content-Type': 'application/json'};

      // PASO 1: Crear el Tenant/Organización
      final tenantResponse = await http
          .post(
            Uri.parse(tenantsUrl),
            headers: headers,
            body: jsonEncode({
              'name': organizationName,
              'domain': domain,
              'description': 'LDAP Managed Organization ($hostingMode)',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (tenantResponse.statusCode != 200 &&
          tenantResponse.statusCode != 201) {
        return {
          'success': false,
          'message':
              'Error al crear organización: ${tenantResponse.statusCode}',
        };
      }

      final tenantData = jsonDecode(tenantResponse.body);
      final String orgId = tenantData['data']['id'];

      // PASO 2: Configurar LDAP para esta organización
      final ldapConfigUrl = '$tenantsUrl/$orgId/ldap/config';
      final configResponse = await http
          .post(
            Uri.parse(ldapConfigUrl),
            headers: headers,
            body: jsonEncode({
              'ldapUrl': ldapUrl,
              'ldapBaseDn': baseDn ?? dc,
              'ldapBindDn': adminCn,
              'ldapBindPassword': adminPassword,
              'userSearchFilter': '(&(objectClass=person)(uid={0}))',
              'emailAttribute': 'mail',
              'fullNameAttribute': 'cn',
              'enabled': true,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (configResponse.statusCode == 200) {
        return {
          'success': true,
          'message': 'Organización y LDAP configurados exitosamente',
          'data': {
            'orgId': orgId,
            'domain': domain,
            'ldapEnabled': true,
          },
        };
      } else {
        return {
          'success': false,
          'message': 'Organización creada pero falló la configuración LDAP',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Error de conexión con el servidor',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Registrar organización self-hosted (nuevo endpoint)
  Future<Map<String, dynamic>> registerSelfHosted({
    required String ldapUrl,
    required String ldapBaseDn,
    required String ldapBindDn,
    required String ldapBindPassword,
    required String orgName,
    String userSearchFilter = "(&(objectClass=person)(uid={0}))",
    String emailAttribute = "mail",
    String fullNameAttribute = "cn",
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register/self-hosted'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ldapUrl': ldapUrl,
              'ldapBaseDn': ldapBaseDn,
              'ldapBindDn': ldapBindDn,
              'ldapBindPassword': ldapBindPassword,
              'userSearchFilter': userSearchFilter,
              'emailAttribute': emailAttribute,
              'fullNameAttribute': fullNameAttribute,
              'orgName': orgName,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Timeout al registrar organización'),
          );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Registro exitoso',
          'data': {
            'userId': data['userId'],
            'orgId': data['orgId'],
            'email': data['email'],
          },
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Error en registro',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

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
    }
  }
}
