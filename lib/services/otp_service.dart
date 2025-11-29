import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Servicio para generar códigos TOTP (Time-based One-Time Password)
/// Implementación según RFC 6238 (TOTP) y RFC 4226 (HOTP)
class OtpService {
  /// Genera un código TOTP basado en el secreto proporcionado
  /// 
  /// [secret] - Clave secreta en Base32
  /// [digits] - Número de dígitos del código (por defecto 6)
  /// [period] - Período de validez en segundos (por defecto 30)
  /// [algorithm] - Algoritmo hash (SHA1, SHA256, SHA512)
  /// [timestamp] - Timestamp opcional para generar código en momento específico
  String generateTotp({
    required String secret,
    int digits = 6,
    int period = 30,
    String algorithm = 'SHA1',
    DateTime? timestamp,
  }) {
    final time = timestamp ?? DateTime.now();
    final counter = time.millisecondsSinceEpoch ~/ 1000 ~/ period;
    
    return _generateHotp(
      secret: secret,
      counter: counter,
      digits: digits,
      algorithm: algorithm,
    );
  }

  /// Genera un código HOTP (HMAC-based One-Time Password)
  String _generateHotp({
    required String secret,
    required int counter,
    int digits = 6,
    String algorithm = 'SHA1',
  }) {
    // Decodificar secreto Base32
    final key = _base32Decode(secret);
    
    // Convertir counter a bytes (8 bytes, big-endian)
    final counterBytes = _intToBytes(counter);
    
    // Calcular HMAC
    final hmacResult = _calculateHmac(key, counterBytes, algorithm);
    
    // Truncamiento dinámico
    final offset = hmacResult[hmacResult.length - 1] & 0x0f;
    final binary = ((hmacResult[offset] & 0x7f) << 24) |
        ((hmacResult[offset + 1] & 0xff) << 16) |
        ((hmacResult[offset + 2] & 0xff) << 8) |
        (hmacResult[offset + 3] & 0xff);
    
    // Generar código con el número de dígitos especificado
    final otp = binary % _pow10(digits);
    
    return otp.toString().padLeft(digits, '0');
  }

  /// Calcula el tiempo restante antes de que el código expire
  int getRemainingSeconds({int period = 30}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return period - (now % period);
  }

  /// Calcula el progreso del período actual (0.0 a 1.0)
  double getProgress({int period = 30}) {
    final remaining = getRemainingSeconds(period: period);
    return remaining / period;
  }

  /// Decodifica una cadena Base32 a bytes
  Uint8List _base32Decode(String input) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    
    // Limpiar input (mayúsculas, sin espacios ni guiones)
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[\s=-]'), '');
    
    if (cleaned.isEmpty) {
      throw FormatException('Empty Base32 string');
    }
    
    // Validar caracteres
    for (final char in cleaned.split('')) {
      if (!base32Chars.contains(char)) {
        throw FormatException('Invalid Base32 character: $char');
      }
    }
    
    final bits = StringBuffer();
    for (final char in cleaned.split('')) {
      final value = base32Chars.indexOf(char);
      bits.write(value.toRadixString(2).padLeft(5, '0'));
    }
    
    final bitString = bits.toString();
    final bytes = <int>[];
    
    for (var i = 0; i + 8 <= bitString.length; i += 8) {
      bytes.add(int.parse(bitString.substring(i, i + 8), radix: 2));
    }
    
    return Uint8List.fromList(bytes);
  }

  /// Convierte un entero a bytes (8 bytes, big-endian)
  Uint8List _intToBytes(int value) {
    final bytes = Uint8List(8);
    for (var i = 7; i >= 0; i--) {
      bytes[i] = value & 0xff;
      value >>= 8;
    }
    return bytes;
  }

  /// Calcula HMAC usando el algoritmo especificado
  List<int> _calculateHmac(Uint8List key, Uint8List data, String algorithm) {
    Hmac hmac;
    
    switch (algorithm.toUpperCase()) {
      case 'SHA256':
        hmac = Hmac(sha256, key);
        break;
      case 'SHA512':
        hmac = Hmac(sha512, key);
        break;
      case 'SHA1':
      default:
        hmac = Hmac(sha1, key);
        break;
    }
    
    return hmac.convert(data).bytes;
  }

  /// Calcula 10^n
  int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  /// Genera un secreto aleatorio en Base32
  String generateSecret({int length = 32}) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    
    var seed = random;
    for (var i = 0; i < length; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      buffer.write(base32Chars[seed % 32]);
    }
    
    return buffer.toString();
  }

  /// Valida si un secreto Base32 es válido
  bool isValidSecret(String secret) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final cleaned = secret.toUpperCase().replaceAll(RegExp(r'[\s=-]'), '');
    
    if (cleaned.isEmpty) return false;
    
    for (final char in cleaned.split('')) {
      if (!base32Chars.contains(char)) {
        return false;
      }
    }
    
    return true;
  }

  /// Formatea el código OTP para mostrar (ej: "123 456")
  String formatCode(String code) {
    if (code.length <= 3) return code;
    
    final mid = code.length ~/ 2;
    return '${code.substring(0, mid)} ${code.substring(mid)}';
  }
}
