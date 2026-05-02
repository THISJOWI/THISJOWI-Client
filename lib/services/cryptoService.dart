import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/api.dart';

class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _algorithm = X25519();
  final _cipher = AesGcm.with256bits();
  final _storage = const FlutterSecureStorage();

  static const String _privateKeyKey = 'e2ee_private_key_v2';
  static const String _publicKeyKey = 'e2ee_public_key_v2';

  // In-memory cache to prevent flickering and redundant network calls
  final Map<String, String> _publicKeyCache = {};
  // Helper to read with fallback (fixes MacOS -34018 error)
  Future<String?> _safeRead(String key) async {
    try {
      final val = await _storage.read(key: key);
      if (val != null) return val;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('flutter: Info: SecureStorage read failed, using SharedPreferences fallback: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Helper to write with fallback
  Future<void> _safeWrite(String key, String value) async {
    bool secureSuccess = false;
    try {
      await _storage.write(key: key, value: value);
      secureSuccess = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('flutter: Info: SecureStorage write failed, using SharedPreferences fallback: $e');
      }
    }
    // Always store in SharedPreferences as well for redundancy
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    if (!secureSuccess) {
      if (kDebugMode) {
        debugPrint('flutter: Info: Key stored in SharedPreferences only (Fallback Active)');
      }
    }
  }

  /// Generates and stores a new keypair if one doesn't exist
  Future<void> initKeys() async {
    if (kDebugMode) {
      debugPrint('flutter: Info: Initializing Advanced E2EE...');
    }
    try {
      String? priv = await _safeRead(_privateKeyKey);
      String? pub = await _safeRead(_publicKeyKey);

      if (priv == null || pub == null) {
        if (kDebugMode) {
          debugPrint('flutter: Info: Generating fresh secure keypair...');
        }
        final keyPair = await _algorithm.newKeyPair();
        final publicKey = await keyPair.extractPublicKey();
        final privateKey = await keyPair.extractPrivateKeyBytes();

        final pubBase64 = base64Encode(publicKey.bytes);
        final privBase64 = base64Encode(privateKey);

        await _safeWrite(_privateKeyKey, privBase64);
        await _safeWrite(_publicKeyKey, pubBase64);

        if (kDebugMode) {
          debugPrint('flutter: Info: Advanced E2EE keys generated');
        }
        await uploadPublicKey(pubBase64);
      } else {
        if (kDebugMode) {
          debugPrint('flutter: Info: Advanced E2EE keys loaded. Syncing...');
        }
        await uploadPublicKey(pub);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('flutter: Error: CRITICAL: Error during E2EE setup: $e');
      }
    }
  }

  Future<void> uploadPublicKey(String publicKey) async {
    try {
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();
      if (token == null) return;

      final res = await http.put(
        Uri.parse('${ApiConfig.authUrl}/user/public-key'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'publicKey': publicKey}),
      );

      if (res.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('flutter: Info: Public key synced with server');
        }
      } else {
        if (kDebugMode) {
          debugPrint('flutter: Error: Server sync failed: ${res.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('flutter: Error: Network error syncing public key: $e');
      }
    }
  }

  Future<String?> fetchRecipientPublicKey(String userId) async {
    // Check cache first to avoid flickering
    if (_publicKeyCache.containsKey(userId)) {
      return _publicKeyCache[userId];
    }

    try {
      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();
      if (token == null) return null;

      final res = await http.get(
        Uri.parse('${ApiConfig.authUrl}/user/$userId/public-key'),
        headers: ApiConfig.authHeaders(token),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final key = data['publicKey'] as String?;
        if (key != null && key.isNotEmpty) {
          _publicKeyCache[userId] = key;
          return key;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('flutter: Error: Error fetching recipient key: $e');
      }
    }
    return null;
  }

  /// Derive a strong key using HKDF (HMAC-based Key Derivation Function)
  Future<SecretKey> _deriveHKDF(SecretKey sharedSecret) async {
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    );
    return await hkdf.deriveKey(
      secretKey: sharedSecret,
      info: utf8.encode('thisjowi-e2ee-v2'),
    );
  }

  /// Advanced Encryption (v2)
  Future<Map<String, String>?> encryptMessage(
      String content, String recipientPublicKeyBase64) async {
    try {
      final myPrivBase64 = await _safeRead(_privateKeyKey);
      final myPubBase64 = await _safeRead(_publicKeyKey);
      if (myPrivBase64 == null || myPubBase64 == null) return null;

      final myKeyPair = SimpleKeyPairData(
        base64Decode(myPrivBase64),
        publicKey: SimplePublicKey(base64Decode(myPubBase64),
            type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );
      final recPub = SimplePublicKey(base64Decode(recipientPublicKeyBase64),
          type: KeyPairType.x25519);

      // 1. ECDH Shared Secret
      final rawSecret = await _algorithm.sharedSecretKey(
          keyPair: myKeyPair, remotePublicKey: recPub);

      // 2. HKDF Key Derivation
      final sessionKey = await _deriveHKDF(rawSecret);

      // 3. AES-GCM Encryption
      final secretBox =
          await _cipher.encrypt(utf8.encode(content), secretKey: sessionKey);

      final encrypted = base64Encode(secretBox.concatenation());

      return {
        'encryptedContent': 'v2:$encrypted',
        'ephemeralPublicKey': myPubBase64,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('flutter: Error: Encryption Error: $e');
      }
      return null;
    }
  }

  /// Advanced Decryption (v2)
  Future<String?> decryptMessage(
      String content, String otherPartyPublicKeyBase64) async {
    try {
      final isV2 = content.startsWith('v2:');
      final cleanContent = isV2 ? content.substring(3) : content;

      final myPrivBase64 = await _safeRead(_privateKeyKey);
      final myPubBase64 = await _safeRead(_publicKeyKey);
      if (myPrivBase64 == null || myPubBase64 == null) return null;

      final myKeyPair = SimpleKeyPairData(
        base64Decode(myPrivBase64),
        publicKey: SimplePublicKey(base64Decode(myPubBase64),
            type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );
      final otherPub = SimplePublicKey(base64Decode(otherPartyPublicKeyBase64),
          type: KeyPairType.x25519);

      // 1. ECDH Shared Secret
      final rawSecret = await _algorithm.sharedSecretKey(
          keyPair: myKeyPair, remotePublicKey: otherPub);

      // 2. HKDF Key Derivation (v2 always, v1 fallback would not use this)
      final sessionKey = isV2 ? await _deriveHKDF(rawSecret) : rawSecret;

      // 3. AES-GCM Decryption
      final secretBox = SecretBox.fromConcatenation(
        base64Decode(cleanContent),
        nonceLength: _cipher.nonceLength,
        macLength: _cipher.macAlgorithm.macLength,
      );

      final clearText = await _cipher.decrypt(secretBox, secretKey: sessionKey);
      return utf8.decode(clearText);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('flutter: Error: Decryption Error: $e');
      }
      return null;
    }
  }
}
