import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/exceptions/auth_exceptions.dart';
import 'package:thisjowi/data/models/auth_user.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/services/base_service.dart';
import 'package:thisjowi/services/cryptoService.dart';
import 'package:thisjowi/services/token_manager.dart';

class GithubAuthService extends BaseService {
  static final GithubAuthService _instance = GithubAuthService._internal();
  factory GithubAuthService() => _instance;
  GithubAuthService._internal() : super('GithubAuthService');

  final TokenManager _tokenManager = TokenManager();
  final CryptoService _cryptoService = CryptoService();
  final SecureStorageService _secureStorage = SecureStorageService();

  static const String _clientId = 'Ov23lilKdhbjWe8OZhYe';
  static const String _redirectUri = 'thisjowi://callback';
  static const String _scope = 'user:email';

  @override
  void validateResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return;
      case 400:
        throw AuthException(
          message: extractErrorMessage(response),
          code: 'VALIDATION_ERROR',
        );
      case 401:
        throw InvalidCredentialsException(
          message: extractErrorMessage(response),
        );
      default:
        throw AuthException(
          message: extractErrorMessage(response),
          code: 'GITHUB_AUTH_ERROR',
        );
    }
  }

  Future<AuthUser> login() async {
    logInfo('Iniciando login GitHub OAuth');

    try {
      final authUrl = Uri.https('github.com', '/login/oauth/authorize', {
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'scope': _scope,
      });

      logInfo('Abriendo GitHub OAuth URL: $authUrl');

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'thisjowi',
      );

      logInfo('Callback recibido: $result');

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

      if (code == null || code.isEmpty) {
        throw AuthException(
          message: 'No se recibio codigo de autorizacion de GitHub',
          code: 'NO_AUTH_CODE',
        );
      }

      return _sendToBackend(code: code);
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error en login GitHub', e, stackTrace);
      throw AuthException(
        message: 'Error al iniciar sesion con GitHub',
        code: 'GITHUB_LOGIN_ERROR',
        details: e,
      );
    }
  }

  Future<AuthUser> _sendToBackend({required String code}) async {
    logInfo('Enviando codigo GitHub al backend');

    try {
      final uri = Uri.parse('${ApiConfig.authUrl}/github');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code}),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200 && res.statusCode != 201) {
        final msg = _parseError(res.body);
        throw AuthException(
          message: msg,
          code: 'BACKEND_ERROR',
        );
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final authUser = AuthUser.fromJson(body);

      await _tokenManager.setToken(
        authUser.token,
        expiry: authUser.tokenExpiry,
        refreshToken: authUser.refreshToken,
      );
      await _tokenManager.setUserId(authUser.id);
      await _secureStorage.saveValue('cached_email', authUser.email);

      await _cryptoService.initKeys();

      logInfo('Login GitHub exitoso: ${authUser.id}');
      return authUser;
    } on AuthException {
      rethrow;
    } on SocketException catch (e) {
      logWarning('Network error: $e');
      throw NetworkException(
        message: 'Error de conexion',
        details: e,
      );
    } catch (e, stackTrace) {
      logError('Error enviando codigo a backend', e, stackTrace);
      throw AuthException(
        message: 'Error al autenticar con servidor',
        code: 'BACKEND_ERROR',
        details: e,
      );
    }
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message'] ?? json['error'] ?? 'Error del servidor';
    } catch (_) {
      return 'Error del servidor';
    }
  }

  void dispose() {}
}
