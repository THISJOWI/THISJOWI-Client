import 'dart:convert';
import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  // TODO: Move this key to a secure environment variable or key management system
  // 32 bytes key for AES-256
  static const String _keyString = 'ThisJowiSecureKeyForOtpEncryption2025!'; 
  
  static String encrypt(String plainText) {
    final key = Key.fromUtf8(_keyString.substring(0, 32));
    final iv = IV.fromLength(16);
    
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Return IV + Encrypted Data encoded in Base64
    // We combine IV and ciphertext to send them together
    final combined = iv.bytes + encrypted.bytes;
    return base64.encode(combined);
  }

  static String decrypt(String encryptedText) {
    try {
      final key = Key.fromUtf8(_keyString.substring(0, 32));
      
      final decoded = base64.decode(encryptedText);
      if (decoded.length < 16) return encryptedText; // Not valid encrypted string
      
      final ivBytes = decoded.sublist(0, 16);
      final cipherBytes = decoded.sublist(16);
      
      final iv = IV(ivBytes);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      
      return encrypter.decrypt(Encrypted(cipherBytes), iv: iv);
    } catch (e) {
      // If decryption fails, return original text (might be plain text)
      return encryptedText;
    }
  }
}
