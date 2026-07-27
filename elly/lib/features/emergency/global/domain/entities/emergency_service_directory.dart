/// emergency_service_directory.dart
///
/// 100% offline versioned directory mapping international emergency numbers, embassies, and regional variations.

library;

import 'country_profile.dart';

class EmergencyServiceDirectory {
  static const String version = '2026.1';

  static const Map<String, CountryProfile> _directory = {
    'IN': CountryProfile(
      countryCode: 'IN',
      countryName: 'India',
      region: 'South Asia',
      defaultLanguage: 'hi_IN',
      timeZone: 'Asia/Kolkata',
      currency: 'INR',
      medicalNumber: '108',
      policeNumber: '100',
      fireNumber: '101',
      embassyContact: EmbassyContact(
        name: 'US Embassy New Delhi',
        phone: '+91 11 2419 8000',
        address: 'Shantipath, Chanakyapuri',
        city: 'New Delhi',
      ),
      regionProfiles: [
        RegionProfile(
          regionCode: 'MH',
          regionName: 'Maharashtra',
          medicalNumber: '108',
          policeNumber: '100',
          fireNumber: '101',
        ),
        RegionProfile(
          regionCode: 'KA',
          regionName: 'Karnataka',
          medicalNumber: '108',
          policeNumber: '100',
          fireNumber: '101',
        ),
      ],
    ),
    'US': CountryProfile(
      countryCode: 'US',
      countryName: 'United States',
      region: 'North America',
      defaultLanguage: 'en_US',
      timeZone: 'America/New_York',
      currency: 'USD',
      medicalNumber: '911',
      policeNumber: '911',
      fireNumber: '911',
      disasterNumber: '911',
      unitSystem: 'imperial',
      embassyContact: EmbassyContact(
        name: 'Indian Embassy Washington DC',
        phone: '+1 202 939 7000',
        address: '2107 Massachusetts Ave NW',
        city: 'Washington, D.C.',
      ),
    ),
    'CA': CountryProfile(
      countryCode: 'CA',
      countryName: 'Canada',
      region: 'North America',
      defaultLanguage: 'en_CA',
      timeZone: 'America/Toronto',
      currency: 'CAD',
      medicalNumber: '911',
      policeNumber: '911',
      fireNumber: '911',
      disasterNumber: '911',
      embassyContact: EmbassyContact(
        name: 'Indian High Commission Ottawa',
        phone: '+1 613 744 3751',
        address: '10 Springfield Rd',
        city: 'Ottawa',
      ),
    ),
    'GB': CountryProfile(
      countryCode: 'GB',
      countryName: 'United Kingdom',
      region: 'Europe',
      defaultLanguage: 'en_GB',
      timeZone: 'Europe/London',
      currency: 'GBP',
      medicalNumber: '999',
      policeNumber: '999',
      fireNumber: '999',
      unitSystem: 'imperial',
      embassyContact: EmbassyContact(
        name: 'Indian High Commission London',
        phone: '+44 20 7836 9147',
        address: 'India House, Aldwych',
        city: 'London',
      ),
    ),
    'EU': CountryProfile(
      countryCode: 'EU',
      countryName: 'European Union',
      region: 'Europe',
      defaultLanguage: 'en_EU',
      timeZone: 'Europe/Paris',
      currency: 'EUR',
      medicalNumber: '112',
      policeNumber: '112',
      fireNumber: '112',
    ),
    'AU': CountryProfile(
      countryCode: 'AU',
      countryName: 'Australia',
      region: 'Oceania',
      defaultLanguage: 'en_AU',
      timeZone: 'Australia/Sydney',
      currency: 'AUD',
      medicalNumber: '000',
      policeNumber: '000',
      fireNumber: '000',
      disasterNumber: '000',
    ),
    'JP': CountryProfile(
      countryCode: 'JP',
      countryName: 'Japan',
      region: 'East Asia',
      defaultLanguage: 'ja_JP',
      timeZone: 'Asia/Tokyo',
      currency: 'JPY',
      medicalNumber: '119',
      policeNumber: '110',
      fireNumber: '119',
      disasterNumber: '119',
      embassyContact: EmbassyContact(
        name: 'Indian Embassy Tokyo',
        phone: '+81 3 3262 2391',
        address: '2-2-11 Kudan-Minami, Chiyoda-ku',
        city: 'Tokyo',
      ),
    ),
    'NZ': CountryProfile(
      countryCode: 'NZ',
      countryName: 'New Zealand',
      region: 'Oceania',
      defaultLanguage: 'en_NZ',
      timeZone: 'Pacific/Auckland',
      currency: 'NZD',
      medicalNumber: '111',
      policeNumber: '111',
      fireNumber: '111',
      disasterNumber: '111',
    ),
    'SG': CountryProfile(
      countryCode: 'SG',
      countryName: 'Singapore',
      region: 'Southeast Asia',
      defaultLanguage: 'en_SG',
      timeZone: 'Asia/Singapore',
      currency: 'SGD',
      medicalNumber: '995',
      policeNumber: '999',
      fireNumber: '995',
      disasterNumber: '995',
    ),
    'BR': CountryProfile(
      countryCode: 'BR',
      countryName: 'Brazil',
      region: 'South America',
      defaultLanguage: 'pt_BR',
      timeZone: 'America/Sao_Paulo',
      currency: 'BRL',
      medicalNumber: '192',
      policeNumber: '190',
      fireNumber: '193',
      disasterNumber: '192',
    ),
    'MX': CountryProfile(
      countryCode: 'MX',
      countryName: 'Mexico',
      region: 'North America',
      defaultLanguage: 'es_MX',
      timeZone: 'America/Mexico_City',
      currency: 'MXN',
      medicalNumber: '911',
      policeNumber: '911',
      fireNumber: '911',
      disasterNumber: '911',
    ),
  };

  /// Returns the CountryProfile for the specified ISO country code, or falls back to India/Global.
  static CountryProfile getProfile(String isoCountryCode) {
    final code = isoCountryCode.toUpperCase();
    if (_directory.containsKey(code)) {
      return _directory[code]!;
    }
    return _directory['IN']!;
  }
}
