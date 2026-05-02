/// Excepciones especificas para el servicio de perfil
library;

/// Excepcion base para errores de perfil
class ProfileException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const ProfileException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'ProfileException: $message (code: $code)';
}

/// Perfil no encontrado
class ProfileNotFoundException extends ProfileException {
  const ProfileNotFoundException({
    super.message = 'Perfil de usuario no encontrado',
    super.details,
  }) : super(
          code: 'PROFILE_NOT_FOUND',
        );
}

/// Error al actualizar perfil
class ProfileUpdateException extends ProfileException {
  const ProfileUpdateException({
    super.message = 'Error al actualizar el perfil',
    super.details,
  }) : super(
          code: 'PROFILE_UPDATE_ERROR',
        );
}

/// Error al subir avatar
class AvatarUploadException extends ProfileException {
  const AvatarUploadException({
    super.message = 'Error al subir la imagen de perfil',
    super.details,
  }) : super(
          code: 'AVATAR_UPLOAD_ERROR',
        );
}

/// Archivo de avatar invalido
class InvalidAvatarException extends ProfileException {
  const InvalidAvatarException({
    super.message = 'El archivo de imagen no es valido',
    super.details,
  }) : super(
          code: 'INVALID_AVATAR',
        );
}

/// Error con clave publica
class PublicKeyException extends ProfileException {
  const PublicKeyException({
    super.message = 'Error con la clave publica',
    super.details,
  }) : super(
          code: 'PUBLIC_KEY_ERROR',
        );
}

/// Error al sincronizar perfil
class ProfileSyncException extends ProfileException {
  const ProfileSyncException({
    super.message = 'Error al sincronizar el perfil',
    super.details,
  }) : super(
          code: 'PROFILE_SYNC_ERROR',
        );
}

/// Error de validacion de datos de perfil
class ProfileValidationException extends ProfileException {
  final Map<String, String>? fieldErrors;

  const ProfileValidationException({
    super.message = 'Datos de perfil invalidos',
    this.fieldErrors,
    super.details,
  }) : super(
          code: 'PROFILE_VALIDATION_ERROR',
        );
}

/// Error de red para perfil
class ProfileNetworkException extends ProfileException {
  const ProfileNetworkException({
    super.message = 'Error de conexion al obtener perfil',
    super.details,
  }) : super(
          code: 'PROFILE_NETWORK_ERROR',
        );
}

/// Error del servidor para perfil
class ProfileServerException extends ProfileException {
  final int statusCode;

  const ProfileServerException({
    required this.statusCode,
    super.message = 'Error del servidor al procesar perfil',
    super.details,
  }) : super(
          code: 'PROFILE_SERVER_ERROR_$statusCode',
        );
}
