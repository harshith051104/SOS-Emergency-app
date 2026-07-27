/// phone_normalizer.dart
///
/// International E.164 phone number validator and normalizer.

library;

class PhoneNormalizer {
  /// Map of ISO country codes to international dial calling codes.
  static const Map<String, String> _dialCodes = {
    'IN': '+91',
    'US': '+1',
    'CA': '+1',
    'GB': '+44',
    'AU': '+61',
    'JP': '+81',
    'NZ': '+64',
    'SG': '+65',
    'BR': '+55',
    'MX': '+52',
  };

  /// Normalizes a raw phone string into E.164 standard format.
  static String normalize(String rawPhone, {String defaultCountryCode = 'IN'}) {
    final cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.isEmpty) return rawPhone;

    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    final dialCode = _dialCodes[defaultCountryCode.toUpperCase()] ?? '+91';

    // Remove leading zeros before prepending dial code
    final trimmedDigits = cleaned.replaceFirst(RegExp(r'^0+'), '');
    return '$dialCode$trimmedDigits';
  }
}
