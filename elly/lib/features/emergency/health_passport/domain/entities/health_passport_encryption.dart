/// health_passport_encryption.dart
///
/// Encryption boundary abstraction decoupling local/cloud storage from key management.
///
/// Production implementation: AES-256-CBC with a device-unique key derived from
/// the app's package name + device ID fingerprint (salted). The key is stored
/// in SharedPreferences and generated on first launch.
///
/// Security properties:
///   - AES-256 CBC mode with random IV per encryption call
///   - PKCS7 padding
///   - Key is 32 bytes (256 bits) generated via secure random on first use
///   - IV is prepended to the ciphertext and stripped on decryption
///   - If key storage fails, falls back to plaintext with a warning log
///
/// NOTE: For maximum security, replace SharedPreferences key storage with
/// flutter_secure_storage (iOS Keychain / Android Keystore). This is documented
/// as a future upgrade. The current approach protects against casual data
/// access but not against rooted devices with direct SharedPreferences access.

library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elly/core/utils/app_logger.dart';

abstract class HealthPassportEncryption {
  Future<String> encrypt(String payload);
  Future<String> decrypt(String encryptedPayload);
}

/// AES-256-CBC implementation with per-encryption random IV.
class AesHealthEncryption implements HealthPassportEncryption {
  AesHealthEncryption(this._prefs);

  final SharedPreferences _prefs;
  static const _keyStorageKey = 'elly_hp_aes_key_v1';

  Future<enc.Key> _getOrCreateKey() async {
    final stored = _prefs.getString(_keyStorageKey);
    if (stored != null) {
      try {
        return enc.Key(base64Decode(stored));
      } catch (_) {
        // Corrupted key — regenerate
        appLogger.warning('AesHealthEncryption: Stored key corrupted, regenerating.');
      }
    }

    // Generate a new 32-byte (256-bit) random key
    final rng = Random.secure();
    final keyBytes = Uint8List.fromList(
        List<int>.generate(32, (_) => rng.nextInt(256)));
    final keyBase64 = base64Encode(keyBytes);
    await _prefs.setString(_keyStorageKey, keyBase64);
    appLogger.info('AesHealthEncryption: New AES-256 key generated and stored.');
    return enc.Key(keyBytes);
  }

  @override
  Future<String> encrypt(String payload) async {
    try {
      final key = await _getOrCreateKey();
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(payload, iv: iv);

      // Prepend IV bytes to ciphertext bytes, then base64-encode the whole thing
      final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
      return base64Encode(combined);
    } catch (e, st) {
      appLogger.error('AesHealthEncryption: Encryption failed, storing plaintext as fallback', e, st);
      // Fallback: store unencrypted with a prefix marker so decrypt can detect it
      return 'PLAINTEXT:${base64Encode(utf8.encode(payload))}';
    }
  }

  @override
  Future<String> decrypt(String encryptedPayload) async {
    try {
      // Handle unencrypted fallback marker
      if (encryptedPayload.startsWith('PLAINTEXT:')) {
        appLogger.warning('AesHealthEncryption: Decrypting plaintext fallback payload.');
        return utf8.decode(base64Decode(encryptedPayload.substring(10)));
      }

      final combined = base64Decode(encryptedPayload);
      if (combined.length < 17) {
        throw FormatException('Ciphertext too short (${combined.length} bytes)');
      }

      final ivBytes = combined.sublist(0, 16);
      final cipherBytes = combined.sublist(16);

      final key = await _getOrCreateKey();
      final iv = enc.IV(ivBytes);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = enc.Encrypted(cipherBytes);

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e, st) {
      appLogger.error('AesHealthEncryption: Decryption failed', e, st);
      // Return empty string rather than crashing — the health passport will
      // show an empty state and the user can re-enter their data.
      return '';
    }
  }
}

/// No-op passthrough for testing environments only.
/// DO NOT USE IN PRODUCTION — data is stored unencrypted.
class PassthroughHealthEncryption implements HealthPassportEncryption {
  @override
  Future<String> encrypt(String payload) async => payload;

  @override
  Future<String> decrypt(String encryptedPayload) async => encryptedPayload;
}
