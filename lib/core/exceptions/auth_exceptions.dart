/// Excepciones especificas para el servicio de autenticacion
library;

/// Excepcion base para errores de autenticacion
class AuthException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AuthException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Credenciales invalidas (email o password incorrectos)
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException({
    super.message = 'Email o contrasena incorrectos',
    super.details,
  }) : super(
          code: 'INVALID_CREDENTIALS',
        );
}

/// Cuenta bloqueada por intentos fallidos
class AccountLockedException extends AuthException {
  final Duration? lockDuration;

  const AccountLockedException({
    super.message = 'Cuenta bloqueada temporalmente',
    this.lockDuration,
    super.details,
  }) : super(
          code: 'ACCOUNT_LOCKED',
        );
}

/// Cuenta no verificada
class AccountNotVerifiedException extends AuthException {
  const AccountNotVerifiedException({
    super.message = 'Cuenta no verificada. Por favor verifica tu email',
    super.details,
  }) : super(
          code: 'ACCOUNT_NOT_VERIFIED',
        );
}

/// Cuenta ya existe
class AccountAlreadyExistsException extends AuthException {
  const AccountAlreadyExistsException({
    super.message = 'Ya existe una cuenta con este email',
    super.details,
  }) : super(
          code: 'ACCOUNT_ALREADY_EXISTS',
        );
}

/// Error en autenticacion OAuth
class OAuthException extends AuthException {
  final String provider;

  const OAuthException({
    required this.provider,
    super.message = 'Error en autenticacion OAuth',
    super.details,
  }) : super(
          code: 'OAUTH_ERROR',
        );
}

/// Error en autenticacion LDAP
class LdapException extends AuthException {
  final String? domain;

  const LdapException({
    super.message = 'Error en autenticacion LDAP',
    this.domain,
    super.details,
  }) : super(
          code: 'LDAP_ERROR',
        );
}

/// Error en autenticacion SAML
class SamlException extends AuthException {
  final String? domain;

  const SamlException({
    super.message = 'Error en autenticacion SAML',
    this.domain,
    super.details,
  }) : super(
          code: 'SAML_ERROR',
        );
}

/// Token expirado
class TokenExpiredException extends AuthException {
  const TokenExpiredException({
    super.message = 'Sesion expirada. Por favor inicia sesion nuevamente',
    super.details,
  }) : super(
          code: 'TOKEN_EXPIRED',
        );
}

/// Token invalido
class TokenInvalidException extends AuthException {
  const TokenInvalidException({
    super.message = 'Token de autenticacion invalido',
    super.details,
  }) : super(
          code: 'TOKEN_INVALID',
        );
}

/// Error en registro
class RegistrationException extends AuthException {
  const RegistrationException({
    super.message = 'Error en el registro',
    super.code = 'REGISTRATION_ERROR',
    super.details,
  });
}

/// OTP invalido o expirado
class OtpInvalidException extends AuthException {
  const OtpInvalidException({
    super.message = 'Codigo de verificacion invalido o expirado',
    super.details,
  }) : super(
          code: 'OTP_INVALID',
        );
}

/// Limite de intentos excedido
class RateLimitExceededException extends AuthException {
  final Duration? retryAfter;

  const RateLimitExceededException({
    super.message = 'Demasiados intentos. Por favor espera un momento',
    this.retryAfter,
    super.details,
  }) : super(
          code: 'RATE_LIMIT_EXCEEDED',
        );
}

/// Error de red
class NetworkException extends AuthException {
  const NetworkException({
    super.message = 'Error de conexion. Verifica tu conexion a internet',
    super.details,
  }) : super(
          code: 'NETWORK_ERROR',
        );
}

/// Timeout de request
class TimeoutException extends AuthException {
  const TimeoutException({
    super.message = 'La solicitud ha tardado demasiado tiempo',
    super.details,
  }) : super(
          code: 'TIMEOUT',
        );
}

/// Error del servidor
class ServerException extends AuthException {
  final int statusCode;

  const ServerException({
    required this.statusCode,
    super.message = 'Error del servidor',
    super.details,
  }) : super(
          code: 'SERVER_ERROR_$statusCode',
        );
}
