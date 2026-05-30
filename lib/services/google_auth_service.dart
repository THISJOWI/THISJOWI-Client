import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/data/models/auth_user.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/services/base_service.dart';
import 'package:thisjowi/services/cryptoService.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/services/oauth2_browser_service.dart';
import 'package:thisjowi/core/exceptions/auth_exceptions.dart';

class GoogleAuthService extends BaseService {
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
          code: 'GOOGLE_AUTH_ERROR',
        );
    }
  }

  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal() : super('GoogleAuthService');

  final TokenManager _tokenManager = TokenManager();
  final CryptoService _cryptoService = CryptoService();
  final SecureStorageService _secureStorage = SecureStorageService();

  final StreamController<AuthUser?> _authStreamController =
      StreamController<AuthUser?>.broadcast();
  Stream<AuthUser?> get onAuthComplete => _authStreamController.stream;

  Future<AuthUser> login() async {
    logInfo('Iniciando login Google OAuth2 (backend flow)');

    try {
      final loginUrl = Uri.parse('${ApiConfig.baseUrl}/v1/auth/login/google');
      final loginRes = await http.get(loginUrl).timeout(const Duration(seconds: 10));

      String authUrlString;
      if (loginRes.statusCode == 200) {
        final body = jsonDecode(loginRes.body) as Map<String, dynamic>;
        authUrlString = body['authorizationUri'] as String? ?? '';
        if (authUrlString.isNotEmpty && !authUrlString.startsWith('http')) {
          authUrlString = '${ApiConfig.baseUrl}$authUrlString';
        }
      } else {
        authUrlString = '${ApiConfig.baseUrl}/oauth2/authorization/google';
      }

      final authUrl = Uri.parse(authUrlString);
      final callback = await OAuth2BrowserService.authenticate(authUrl: authUrl);

      final token = callback.queryParameters['token'];
      final userId = callback.queryParameters['userId'];
      final email = callback.queryParameters['email'];
      final name = callback.queryParameters['name'];
      final picture = callback.queryParameters['picture'];

      if (token == null || token.isEmpty) {
        throw AuthException(
          message: 'No se recibio el token de autenticacion',
          code: 'NO_TOKEN',
        );
      }

      logInfo('Callback OAuth2 recibido: userId=$userId, email=$email');

      final authUser = AuthUser.fromJson({
        'token': token,
        'userId': userId ?? '',
        'email': email ?? '',
        'name': name ?? '',
        'picture': picture ?? '',
      });

      await _tokenManager.setToken(
        authUser.token,
        expiry: authUser.tokenExpiry,
        refreshToken: authUser.refreshToken,
      );
      await _tokenManager.setUserId(authUser.id);
      await _secureStorage.saveValue('cached_email', authUser.email);

      await _cryptoService.initKeys();

      logInfo('Login Google exitoso: ${authUser.id}');
      return authUser;
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error en login Google', e, stackTrace);
      throw AuthException(
        message: 'Error al iniciar sesion con Google',
        code: 'GOOGLE_LOGIN_ERROR',
        details: e,
      );
    }
  }

  void dispose() {
    _authStreamController.close();
  }
}
