/// health_passport_encryption.dart
///
/// Encryption boundary abstraction decoupling local/cloud storage from security key management.

library;

abstract class HealthPassportEncryption {
  Future<String> encrypt(String payload);
  Future<String> decrypt(String encryptedPayload);
}

class PassthroughHealthEncryption implements HealthPassportEncryption {
  @override
  Future<String> encrypt(String payload) async => payload;

  @override
  Future<String> decrypt(String encryptedPayload) async => encryptedPayload;
}
