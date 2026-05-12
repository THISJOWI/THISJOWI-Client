import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/data/models/auth_user.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/services/base_service.dart';
import 'package:thisjowi/services/cryptoService.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/core/exceptions/auth_exceptions.dart';

class GoogleAuthService extends BaseService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal() : super('GoogleAuthService');

  final TokenManager _tokenManager = TokenManager();
  final CryptoService _cryptoService = CryptoService();
  final SecureStorageService _secureStorage = SecureStorageService();

  late final GoogleSignIn _googleSignIn;

  final StreamController<AuthUser?> _authStreamController =
      StreamController<AuthUser?>.broadcast();
  Stream<AuthUser?> get onAuthComplete => _authStreamController.stream;

  GoogleSignIn _initGoogleSignIn() {
    return GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: Platform.isAndroid
          ? '874520303548-le6pq4merb2168869p6jfhmfj7ku968o.apps.googleusercontent.com'
          : Platform.isWindows || Platform.isLinux
              ? '874520303548-le6pq4merb2168869p6jfhmfj7ku968o.apps.googleusercontent.com'
              : null,
    );
  }

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

  Future<AuthUser> login() async {
    logInfo('Iniciando login Google SDK');

    try {
      _googleSignIn = _initGoogleSignIn();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        logInfo('Google sign in cancelado por usuario');
        throw AuthException(
          message: 'Inicio de sesion cancelado',
          code: 'CANCELLED',
        );
      }

      logInfo('Usuario Google: ${googleUser.email}');

      final String? authCode = googleUser.serverAuthCode;
      logInfo('Server Auth Code obtenido: ${authCode != null}');

      if (authCode != null) {
        return _sendToBackend(code: authCode, email: googleUser.email);
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      logInfo('ID Token obtenido: ${idToken != null}');

      if (idToken == null) {
        throw AuthException(
          message: 'No se pudo obtener credenciales de Google',
          code: 'NO_CREDENTIALS',
        );
      }

      return _sendToBackend(token: idToken, email: googleUser.email);
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

  Future<AuthUser> _sendToBackend({
    String? code,
    String? token,
    required String email,
  }) async {
    logInfo('Enviando a backend: code=${code != null}, token=${token != null}');

    try {
      final bodyMap = <String, String>{};
      if (code != null) bodyMap['code'] = code;
      if (token != null) bodyMap['token'] = token;

      // Usar raw http como la impl original que funcionaba
      final uri = Uri.parse('${ApiConfig.authUrl}/google');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyMap),
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

      logInfo('Login Google exitoso: ${authUser.id}');
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
      logError('Error enviando token a backend', e, stackTrace);
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

  void dispose() {
    _authStreamController.close();
  }
}
