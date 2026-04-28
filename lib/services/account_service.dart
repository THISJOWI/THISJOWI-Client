import 'package:http/http.dart' as http;

import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/exceptions/account_exceptions.dart';
import 'package:thisjowi/core/exceptions/auth_exceptions.dart';
import 'package:thisjowi/data/models/account_user.dart';
import 'package:thisjowi/services/base_service.dart';
import 'package:thisjowi/services/token_manager.dart';

/// Servicio de cuenta de usuario
/// Responsabilidad: Gestión de contraseñas, eliminación de cuenta, facturación
class AccountService extends BaseService {
  static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;
  AccountService._internal() : super('AccountService');

  final TokenManager _tokenManager = TokenManager();

  // URL base del servicio de cuenta
  String get _baseUrl => ApiConfig.baseUrl;

  @override
  void validateResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        return;
      case 400:
        throw AccountValidationException(
          message: extractErrorMessage(response),
        );
      case 401:
        throw AccountException(
          message: 'Sesion expirada. Inicia sesion nuevamente.',
          code: 'UNAUTHORIZED',
        );
      case 403:
        final message = extractErrorMessage(response);
        if (message.toLowerCase().contains('password') ||
            message.toLowerCase().contains('contrasena')) {
          throw InvalidCurrentPasswordException(message: message);
        }
        throw AccountException(
          message: message,
          code: 'FORBIDDEN',
        );
      case 404:
        throw const AccountNotFoundException();
      case 422:
        throw InvalidNewPasswordException(
          message: extractErrorMessage(response),
        );
      case 429:
        throw RateLimitExceededException(
          message: 'Demasiados intentos. Espera un momento.',
        );
      case 500:
      case 502:
      case 503:
        throw AccountServerException(
          statusCode: response.statusCode,
          message: 'Error del servidor. Intenta mas tarde.',
        );
      default:
        throw AccountException(
          message: 'Error inesperado: ${response.statusCode}',
          code: 'UNKNOWN_ERROR',
        );
    }
  }

  /// Obtener datos de cuenta
  Future<AccountUser> getAccount(String userId) async {
    logInfo('Fetching account for user: $userId');

    try {
      final response = await apiClient.get(
        '/v1/accounts/$userId',
        requiresAuth: true,
      );

      validateResponse(response);

      final body = parseJsonBody(response);
      final account = AccountUser.fromJson(body);

      logInfo('Account fetched successfully for user: $userId');
      return account;
    } on AccountException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error fetching account', e, stackTrace);
      throw AccountException(
        message: 'Error al obtener cuenta: $e',
        code: 'FETCH_ERROR',
        details: e,
      );
    }
  }

  /// Obtener cuenta del usuario actual
  Future<AccountUser?> getCurrentAccount() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      logWarning('No user ID found for current account');
      return null;
    }
    return getAccount(userId);
  }

  /// Cambiar contraseña
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    logInfo('Changing password');

    // Validar que las contraseñas coincidan
    if (newPassword != confirmPassword) {
      throw const InvalidNewPasswordException(
        message: 'Las contraseñas nuevas no coinciden',
      );
    }

    // Validar longitud minima
    if (newPassword.length < 8) {
      throw const InvalidNewPasswordException(
        message: 'La contraseña debe tener al menos 8 caracteres',
      );
    }

    try {
      final response = await apiClient.put(
        '/v1/accounts/password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
        requiresAuth: true,
      );

      validateResponse(response);

      logInfo('Password changed successfully');
    } on AccountException {
      rethrow;
    } on InvalidCurrentPasswordException {
      rethrow;
    } on InvalidNewPasswordException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error changing password', e, stackTrace);
      throw PasswordChangeException(
        message: 'Error al cambiar contraseña: $e',
        details: e,
      );
    }
  }

  /// Solicitar recuperación de contraseña (forgot password)
  Future<void> forgotPassword(String email) async {
    logInfo('Requesting password reset for: $email');

    try {
      final response = await apiClient.post(
        '/v1/accounts/forgot-password',
        body: {'email': email},
        requiresAuth: false,
      );

      validateResponse(response);

      logInfo('Password reset requested successfully for: $email');
    } on AccountException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error requesting password reset', e, stackTrace);
      throw PasswordResetException(
        message: 'Error al solicitar reseteo: $e',
        details: e,
      );
    }
  }

  /// Resetear contraseña con token
  Future<void> resetPassword(String token, String newPassword) async {
    logInfo('Resetting password with token');

    // Validar longitud minima
    if (newPassword.length < 8) {
      throw const InvalidNewPasswordException(
        message: 'La contraseña debe tener al menos 8 caracteres',
      );
    }

    try {
      final response = await apiClient.post(
        '/v1/accounts/reset-password',
        body: {
          'token': token,
          'newPassword': newPassword,
        },
        requiresAuth: false,
      );

      validateResponse(response);

      logInfo('Password reset successfully');
    } on AccountException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error resetting password', e, stackTrace);
      throw PasswordResetException(
        message: 'Error al resetear contraseña: $e',
        details: e,
      );
    }
  }

  /// Eliminar cuenta
  Future<void> deleteAccount(String password) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw const AccountException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    logInfo('Deleting account for user: $userId');

    try {
      final response = await apiClient.delete(
        '/v1/accounts/$userId',
        body: {'password': password},
        requiresAuth: true,
      );

      validateResponse(response);

      // Limpiar tokens locales
      await _tokenManager.clearToken();

      logInfo('Account deleted successfully');
    } on AccountException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error deleting account', e, stackTrace);
      throw AccountDeletionException(
        message: 'Error al eliminar cuenta: $e',
        details: e,
      );
    }
  }

  /// Exportar datos de la cuenta (GDPR)
  Future<Map<String, dynamic>> exportData() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw const AccountException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    logInfo('Exporting data for user: $userId');

    try {
      final response = await apiClient.get(
        '/v1/accounts/$userId/export',
        requiresAuth: true,
      );

      validateResponse(response);

      final body = parseJsonBody(response);

      logInfo('Data exported successfully');
      return body;
    } on AccountException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error exporting data', e, stackTrace);
      throw DataExportException(
        message: 'Error al exportar datos: $e',
        details: e,
      );
    }
  }

  /// Actualizar configuración de seguridad
  Future<void> updateSecuritySettings(Map<String, dynamic> settings) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw const AccountException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    logInfo('Updating security settings for user: $userId');

    try {
      final response = await apiClient.put(
        '/v1/accounts/$userId/security-settings',
        body: settings,
        requiresAuth: true,
      );

      validateResponse(response);

      logInfo('Security settings updated successfully');
    } on AccountException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error updating security settings', e, stackTrace);
      throw AccountException(
        message: 'Error al actualizar configuracion: $e',
        code: 'SECURITY_SETTINGS_ERROR',
        details: e,
      );
    }
  }

  /// Obtener configuración de seguridad
  Future<Map<String, dynamic>> getSecuritySettings() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw const AccountException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    logInfo('Fetching security settings for user: $userId');

    try {
      final response = await apiClient.get(
        '/v1/accounts/$userId/security-settings',
        requiresAuth: true,
      );

      validateResponse(response);

      final body = parseJsonBody(response);

      logInfo('Security settings fetched successfully');
      return body;
    } on AccountException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error fetching security settings', e, stackTrace);
      throw AccountException(
        message: 'Error al obtener configuracion: $e',
        code: 'SECURITY_SETTINGS_ERROR',
        details: e,
      );
    }
  }

  /// Verificar si una característica está disponible
  Future<bool> hasFeature(String feature) async {
    try {
      final account = await getCurrentAccount();
      return account?.hasFeature(feature) ?? false;
    } catch (e) {
      logDebug('Error checking feature availability: $e');
      return false;
    }
  }

  /// Verificar si la suscripción está activa
  Future<bool> isSubscriptionActive() async {
    try {
      final account = await getCurrentAccount();
      return account?.isSubscriptionActive ?? false;
    } catch (e) {
      logDebug('Error checking subscription status: $e');
      return false;
    }
  }

  /// Obtener días restantes de suscripción
  Future<int?> getDaysRemaining() async {
    try {
      final account = await getCurrentAccount();
      return account?.daysRemaining;
    } catch (e) {
      logDebug('Error getting days remaining: $e');
      return null;
    }
  }

  /// Verificar si es cuenta Business
  Future<bool> isBusinessAccount() async {
    try {
      final account = await getCurrentAccount();
      return account?.isBusinessAccount ?? false;
    } catch (e) {
      logDebug('Error checking account type: $e');
      return false;
    }
  }

  /// Verificar si es modo Self-Hosted
  Future<bool> isSelfHosted() async {
    try {
      final account = await getCurrentAccount();
      return account?.isSelfHosted ?? false;
    } catch (e) {
      logDebug('Error checking hosting mode: $e');
      return false;
    }
  }
}
