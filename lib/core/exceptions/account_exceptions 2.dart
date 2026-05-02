/// Excepciones especificas para el servicio de cuenta
library;

/// Excepcion base para errores de cuenta
class AccountException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AccountException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AccountException: $message (code: $code)';
}

/// Cuenta no encontrada
class AccountNotFoundException extends AccountException {
  const AccountNotFoundException({
    super.message = 'Cuenta no encontrada',
    super.details,
  }) : super(
          code: 'ACCOUNT_NOT_FOUND',
        );
}

/// Error al cambiar contrasena
class PasswordChangeException extends AccountException {
  const PasswordChangeException({
    super.message = 'Error al cambiar la contrasena',
    super.details,
  }) : super(
          code: 'PASSWORD_CHANGE_ERROR',
        );
}

/// Contrasena actual incorrecta
class InvalidCurrentPasswordException extends AccountException {
  const InvalidCurrentPasswordException({
    super.message = 'La contrasena actual es incorrecta',
    super.details,
  }) : super(
          code: 'INVALID_CURRENT_PASSWORD',
        );
}

/// Contrasena nueva invalida
class InvalidNewPasswordException extends AccountException {
  final List<String>? requirements;

  const InvalidNewPasswordException({
    super.message = 'La nueva contrasena no cumple los requisitos',
    this.requirements,
    super.details,
  }) : super(
          code: 'INVALID_NEW_PASSWORD',
        );
}

/// Error al eliminar cuenta
class AccountDeletionException extends AccountException {
  const AccountDeletionException({
    super.message = 'Error al eliminar la cuenta',
    super.details,
  }) : super(
          code: 'ACCOUNT_DELETION_ERROR',
        );
}

/// Error al resetear contrasena
class PasswordResetException extends AccountException {
  const PasswordResetException({
    super.message = 'Error al resetear la contrasena',
    super.details,
  }) : super(
          code: 'PASSWORD_RESET_ERROR',
        );
}

/// Token de reset invalido o expirado
class InvalidResetTokenException extends AccountException {
  const InvalidResetTokenException({
    super.message = 'El enlace de reseteo ha expirado o es invalido',
    super.details,
  }) : super(
          code: 'INVALID_RESET_TOKEN',
        );
}

/// Error de facturacion
class BillingException extends AccountException {
  const BillingException({
    super.message = 'Error en la facturacion',
    super.details,
  }) : super(
          code: 'BILLING_ERROR',
        );
}

/// Suscripcion expirada
class SubscriptionExpiredException extends AccountException {
  const SubscriptionExpiredException({
    super.message = 'Tu suscripcion ha expirado',
    super.details,
  }) : super(
          code: 'SUBSCRIPTION_EXPIRED',
        );
}

/// Limite de funciones alcanzado
class FeatureLimitExceededException extends AccountException {
  final String? feature;

  const FeatureLimitExceededException({
    super.message = 'Has alcanzado el limite de esta funcion',
    this.feature,
    super.details,
  }) : super(
          code: 'FEATURE_LIMIT_EXCEEDED',
        );
}

/// Error al exportar datos
class DataExportException extends AccountException {
  const DataExportException({
    super.message = 'Error al exportar los datos',
    super.details,
  }) : super(
          code: 'DATA_EXPORT_ERROR',
        );
}

/// Error de validacion de cuenta
class AccountValidationException extends AccountException {
  final Map<String, String>? fieldErrors;

  const AccountValidationException({
    super.message = 'Datos de cuenta invalidos',
    this.fieldErrors,
    super.details,
  }) : super(
          code: 'ACCOUNT_VALIDATION_ERROR',
        );
}

/// Error de red para cuenta
class AccountNetworkException extends AccountException {
  const AccountNetworkException({
    super.message = 'Error de conexion al acceder a la cuenta',
    super.details,
  }) : super(
          code: 'ACCOUNT_NETWORK_ERROR',
        );
}

/// Error del servidor para cuenta
class AccountServerException extends AccountException {
  final int statusCode;

  const AccountServerException({
    required this.statusCode,
    super.message = 'Error del servidor al procesar cuenta',
    super.details,
  }) : super(
          code: 'ACCOUNT_SERVER_ERROR_$statusCode',
        );
}
