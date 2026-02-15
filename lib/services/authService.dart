import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:thisjowi/services/cryptoService.dart';
import '../core/api.dart';
import '../data/models/user.dart';

/// Simple service to connect with the authentication API.
///
/// Contract:
/// - login(email, password) -> Future<Map> { success: bool, data?: Map, message?: String }
/// - register(email, password) -> Future<Map> { success: bool, data?: Map, message?: String }
/// - changePassword(current, new, confirm) -> Future<Map> { success: bool, message?: String, data?: Map }
/// - deleteAccount() -> Future<Map> { success: bool, message?: String }
/// - getToken() -> Future<String?>
/// - getEmail() -> Future<String?>
/// - logout() -> Future<void>
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final CryptoService _cryptoService = CryptoService();

  // URL base del servicio de autenticación desde ApiConfig
  String get baseUrl => ApiConfig.authUrl;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: Platform.isAndroid
        ? '874520303548-5ck3hf71d2n408d83vqi2p4c8mhqmppp.apps.googleusercontent.com'
        : null,
    // serverClientId: 'YOUR_WEB_CLIENT_ID', // Uncomment and set this if you need a server auth code
  );

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      print('DEBUG: Starting Google Sign In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('DEBUG: Google Sign In aborted by user');
        return {'success': false, 'message': 'Google sign in aborted'};
      }

      print('DEBUG: Google User signed in: ${googleUser.email}');

      // Get Server Auth Code (for backend processing)
      final String? authCode = googleUser.serverAuthCode;
      print('DEBUG: Auth Code: $authCode');

      if (authCode == null) {
        print('DEBUG: Auth Code is null, trying ID Token...');
        // Fallback to ID Token if code is null (though serverClientId should ensure code)
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final String? idToken = googleAuth.idToken;
        print('DEBUG: ID Token found: ${idToken != null}');

        if (idToken != null) {
          // Send ID Token (Legacy flow)
          return _sendGoogleTokenToBackend(
              idToken: idToken, email: googleUser.email);
        }
        return {
          'success': false,
          'message': 'Failed to retrieve Google Auth Code'
        };
      }

      // Send Code to backend
      return _sendGoogleTokenToBackend(code: authCode, email: googleUser.email);
    } catch (e, stackTrace) {
      print('DEBUG: Google Sign In Error: $e');
      print(stackTrace);
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _sendGoogleTokenToBackend(
      {String? code, String? idToken, required String email}) async {
    final uri = Uri.parse('$baseUrl/google');
    print('DEBUG: Sending to backend: $uri');

    final bodyMap = <String, String>{};
    if (code != null) bodyMap['code'] = code;
    if (idToken != null) bodyMap['token'] = idToken;

    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyMap),
          )
          .timeout(const Duration(seconds: 30));

      print('DEBUG: Backend response status: ${res.statusCode}');
      print('DEBUG: Backend response body: ${res.body}');

      final body = _tryDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (body != null && body['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', body['token']);
          await prefs.setString('email', email);

          // Initialize E2EE Keys
          await _cryptoService.initKeys();

          return {'success': true, 'data': body};
        }
        return {
          'success': false,
          'message': body?['message'] ?? 'No token returned from backend'
        };
      }
      return {'success': false, 'message': _parseError(res)};
    } catch (e) {
      print('DEBUG: HTTP Request failed: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> loginWithGitHub() async {
    try {
      // GitHub OAuth Configuration
      const String clientId = 'Ov23lilKdhbjWe8OZhYe';
      const String redirectUri = 'thisjowi://callback';
      const String scope = 'user:email';

      final url = Uri.https('github.com', '/login/oauth/authorize', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scope,
      });

      // Open browser and wait for redirect
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'thisjowi',
      );

      // Extract code from result URL
      final code = Uri.parse(result).queryParameters['code'];

      if (code == null) {
        return {
          'success': false,
          'message': 'GitHub sign in aborted or no code returned'
        };
      }

      // Send code to backend
      final uri = Uri.parse('$baseUrl/github');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code, 'redirect_uri': redirectUri}),
          )
          .timeout(const Duration(seconds: 30));

      final body = _tryDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (body != null && body['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', body['token']);
          await prefs.setString('email', body['email']);

          // Initialize E2EE Keys
          await _cryptoService.initKeys();

          return {'success': true, 'data': body};
        }
        return {
          'success': false,
          'message': body?['message'] ?? 'No token returned from backend'
        };
      }
      return {'success': false, 'message': _parseError(res)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/login');

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      final body = _tryDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (body != null && body['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', body['token']);
          await prefs.setString('email', email);

          // Initialize E2EE Keys
          await _cryptoService.initKeys();

          return {'success': true, 'data': body};
        }
        return {
          'success': false,
          'message': body?['message'] ?? 'No token returned'
        };
      }

      return {'success': false, 'message': _parseError(res)};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.'
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> initiateRegister(String email) async {
    try {
      final uri = Uri.parse('$baseUrl/initiate-register');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      final body = _tryDecode(res.body);

      if (res.statusCode == 200) {
        return {'success': true, 'message': body?['message']};
      }
      return {'success': false, 'message': _parseError(res)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password, {
    String? fullName,
    String? country,
    String? accountType,
    String? hostingMode,
    String? birthdate,
    required String otp,
    Map<String, dynamic>? ldapConfig,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/register');
      final bodyData = {
        'email': email,
        'password': password,
        'otp': otp,
      };

      if (fullName != null) bodyData['fullName'] = fullName;
      if (country != null) bodyData['country'] = country;
      if (accountType != null) bodyData['accountType'] = accountType;
      if (hostingMode != null) bodyData['hostingMode'] = hostingMode;
      if (birthdate != null) bodyData['birthdate'] = birthdate;

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyData),
          )
          .timeout(const Duration(seconds: 30));

      final body = _tryDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (body != null && body['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', body['token']);
          if (body['email'] != null) {
            await prefs.setString('email', body['email']);
          }
        }

        // Initialize E2EE Keys
        await _cryptoService.initKeys();
        return {'success': true, 'data': body};
      }

      return {'success': false, 'message': _parseError(res)};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.'
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateUser({
    String? country,
    String? accountType,
    String? hostingMode,
    String? birthdate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final uri = Uri.parse('$baseUrl/user');
      final bodyData = <String, String>{};

      if (country != null) bodyData['country'] = country;
      if (accountType != null) bodyData['accountType'] = accountType;
      if (hostingMode != null) bodyData['hostingMode'] = hostingMode;
      if (birthdate != null) bodyData['birthdate'] = birthdate;

      final res = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(bodyData),
          )
          .timeout(const Duration(seconds: 30));

      final body = _tryDecode(res.body);

      if (res.statusCode == 200) {
        return {'success': true, 'data': body};
      }

      return {'success': false, 'message': _parseError(res)};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.'
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token;
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final uri = Uri.parse(
          '$baseUrl/user'); // Changed from /me to /user based on updateUser pattern
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = _tryDecode(res.body);
        if (body != null) {
          // Response from /user is {"userId": 123}
          final userIdRaw = body['userId'] ?? body['data']?['userId'];

          if (userIdRaw != null) {
            final userId = userIdRaw.toString();
            // Now fetch full details from /user-details/{userId}
            // The backend controller is mapped to /api/v1/auth
            // So the full path is /api/v1/auth/user-details/{userId}

            final detailsUri = Uri.parse('$baseUrl/user-details/$userId');
            try {
              final detailsRes = await http.get(
                detailsUri,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              ).timeout(const Duration(seconds: 10));

              if (detailsRes.statusCode == 200) {
                final detailsBody = _tryDecode(detailsRes.body);
                // Backend sends the User object directly as JSON
                if (detailsBody != null) {
                  final user = User.fromJson(detailsBody);

                  // Cache accountType
                  final prefs = await SharedPreferences.getInstance();
                  if (user.accountType != null) {
                    await prefs.setString('accountType', user.accountType!);
                  }
                  return user;
                }
              }
            } catch (e) {
              print('Error fetching user details: $e');
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  // Get cached account type for synchronous checks
  Future<String?> getCachedAccountType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accountType');
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('email');
  }

  Future<void> setSession(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('email', email);
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword,
      String newPassword, String confirmPassword) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No token found'};

      final uri = Uri.parse('$baseUrl/change-password');
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
              'confirmPassword': confirmPassword,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = _tryDecode(res.body);

      if (res.statusCode == 200) {
        return {'success': true, 'data': body};
      }

      return {
        'success': false,
        'message':
            body?['message'] ?? 'Error changing password: ${res.statusCode}'
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to change password: $e'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final uri = Uri.parse('$baseUrl/forgot-password');
    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      final body = _tryDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': body?['message'] ?? 'OTP sent'};
      } else {
        return {
          'success': false,
          'message': body?['message'] ?? 'Failed to send OTP'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No token found'};

      final uri = Uri.parse('$baseUrl/delete-account');
      final res = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200 || res.statusCode == 204) {
        // Clear token after deleting the account
        await logout();
        return {'success': true, 'message': 'Account deleted successfully'};
      }

      final body = _tryDecode(res.body);
      return {
        'success': false,
        'message':
            body?['message'] ?? 'Error deleting account: ${res.statusCode}'
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete account: $e'};
    }
  }

  dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  String _parseError(http.Response res) {
    try {
      final body = _tryDecode(res.body);
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
        return 'Conflicto. Es posible que el usuario ya exista.';
      case 500:
        return 'Error interno del servidor. Por favor, inténtalo más tarde.';
      default:
        return 'Error: ${res.statusCode}';
    }
  }
}
