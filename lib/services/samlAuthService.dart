import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../data/models/user.dart';

class SamlAuthService {
  String get baseUrl => ApiConfig.authUrl;

  Future<Map<String, dynamic>> loginWithSaml({
    required String domain,
    required String samlResponse,
    String? relayState,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/saml/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'domain': domain,
              'samlResponse': samlResponse,
              if (relayState != null) 'relayState': relayState,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Timeout al conectarse con servidor SAML'),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true || data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token'] ?? data['refreshToken']);
          await prefs.setString('userId', data['userId'].toString());
          await prefs.setString('email', data['email']);
          await prefs.setString('orgId', data['organizationId'] ?? '');
          await prefs.setBool('isSamlUser', true);

          return {
            'success': true,
            'message': 'Autenticación SAML exitosa',
            'data': {
              'user': User(
                id: data['userId']?.toString(),
                email: data['email'],
                orgId: data['organizationId'],
                isSamlUser: true,
                samlNameId: data['samlNameId'],
              ),
              'token': data['token'] ?? data['refreshToken'],
            },
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error en autenticación SAML',
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
        'message': 'Error de conexión con servidor SAML',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

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
          'data': data,
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

  Future<bool> isSamlEnabledForDomain(String domain) async {
    try {
      final response = await getOrganizationByDomain(domain);
      if (response['success'] == true) {
        final data = response['data'];
        return data?['samlEnabled'] == true && data?['isActive'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSamlConfigForDomain(String domain) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/saml/config/$domain'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getIdpMetadataUrl(String domain) async {
    final config = await getSamlConfigForDomain(domain);
    if (config != null) {
      return config['idpMetadataUrl'] ?? config['metadataUrl'];
    }
    return null;
  }

  Future<User?> getSamlUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final email = prefs.getString('email');
      final orgId = prefs.getString('orgId');
      final samlNameId = prefs.getString('samlNameId');
      final isSamlUser = prefs.getBool('isSamlUser') ?? false;

      if (email != null && isSamlUser) {
        return User(
          id: userId,
          email: email,
          orgId: orgId,
          isSamlUser: isSamlUser,
          samlNameId: samlNameId,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearSamlSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('orgId');
      await prefs.remove('samlNameId');
      await prefs.remove('isSamlUser');
    } catch (e) {
      print('Error clearing SAML session: $e');
    }
  }

  Future<Map<String, dynamic>> registerSamlOrganization({
    required String organizationName,
    required String domain,
    required String idpMetadataUrl,
    String? entityId,
    required String hostingMode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final String tenantsUrl = '${ApiConfig.baseUrl}/api/v1/tenants';
      final headers = token != null
          ? {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            }
          : {'Content-Type': 'application/json'};

      final tenantResponse = await http
          .post(
            Uri.parse(tenantsUrl),
            headers: headers,
            body: jsonEncode({
              'name': organizationName,
              'domain': domain,
              'description': 'SAML Managed Organization ($hostingMode)',
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

      final samlConfigUrl = '$tenantsUrl/$orgId/saml/config';
      final configResponse = await http
          .post(
            Uri.parse(samlConfigUrl),
            headers: headers,
            body: jsonEncode({
              'idpMetadataUrl': idpMetadataUrl,
              'spEntityId': entityId ?? 'thisjowi-$orgId',
              'enabled': true,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (configResponse.statusCode == 200) {
        return {
          'success': true,
          'message': 'Organización y SAML configurados exitosamente',
          'data': {
            'orgId': orgId,
            'domain': domain,
            'samlEnabled': true,
          },
        };
      } else {
        return {
          'success': false,
          'message': 'Organización creada pero falló la configuración SAML',
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