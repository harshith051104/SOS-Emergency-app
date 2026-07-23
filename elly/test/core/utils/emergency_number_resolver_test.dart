/// emergency_number_resolver_test.dart
///
/// Unit tests for [EmergencyNumberResolver].

library;

import 'package:elly/core/utils/emergency_number_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmergencyNumberResolver Tests —', () {
    test('resolves correct emergency number for country codes', () {
      expect(EmergencyNumberResolver.resolveNumber(countryCode: 'IN'), '112');
      expect(EmergencyNumberResolver.resolveNumber(countryCode: 'US'), '911');
      expect(EmergencyNumberResolver.resolveNumber(countryCode: 'GB'), '999');
      expect(EmergencyNumberResolver.resolveNumber(countryCode: 'AU'), '000');
      expect(EmergencyNumberResolver.resolveNumber(countryCode: 'NZ'), '111');
      expect(EmergencyNumberResolver.resolveNumber(countryCode: 'DE'), '112');
    });

    test('resolves correct emergency number from locale string', () {
      expect(EmergencyNumberResolver.resolveNumber(localeName: 'en_IN'), '112');
      expect(EmergencyNumberResolver.resolveNumber(localeName: 'en_US'), '911');
      expect(EmergencyNumberResolver.resolveNumber(localeName: 'en_GB'), '999');
      expect(EmergencyNumberResolver.resolveNumber(localeName: 'de_DE'), '112');
    });

    test('resolves correct emergency service numbers based on category and country', () {
      // India (IN)
      expect(EmergencyNumberResolver.resolveServiceNumber(category: 'Medical', countryCode: 'IN'), '102');
      expect(EmergencyNumberResolver.resolveServiceNumber(category: 'Accident', countryCode: 'IN'), '102');
      expect(EmergencyNumberResolver.resolveServiceNumber(category: 'Personal Safety', countryCode: 'IN'), '100');
      expect(EmergencyNumberResolver.resolveServiceNumber(category: 'Fire & Disaster', countryCode: 'IN'), '101');
      expect(EmergencyNumberResolver.resolveServiceNumber(category: 'Mental Health', countryCode: 'IN'), '112');

      // USA (US)
      expect(EmergencyNumberResolver.resolveServiceNumber(category: 'Medical', countryCode: 'US'), '911');
      expect(EmergencyNumberResolver.resolveServiceNumber(category: 'Fire & Disaster', countryCode: 'US'), '911');

      // Japan (JP)
      expect(EmergencyNumberResolver.resolveServiceNumber(category: 'Medical', countryCode: 'JP'), '119');
      expect(EmergencyNumberResolver.resolveServiceNumber(category: 'Personal Safety', countryCode: 'JP'), '110');
    });

    test('returns default GSM 112 for unknown/null inputs', () {
      expect(EmergencyNumberResolver.resolveNumber(countryCode: 'XX'), '112');
      expect(EmergencyNumberResolver.resolveNumber(), '112');
    });
  });
}
