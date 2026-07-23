/// emergency_number_resolver.dart
///
/// Utility service that resolves national & international universal emergency numbers
/// based on the user's country/locale and places direct emergency calls via url_launcher.

library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_logger.dart';

abstract final class EmergencyNumberResolver {
  /// Country ISO code -> Primary national emergency phone number.
  static const Map<String, String> _countryEmergencyNumbers = {
    'IN': '112', // India (112 National Emergency Number)
    'US': '911', // United States
    'CA': '911', // Canada
    'GB': '999', // United Kingdom
    'UK': '999',
    'AU': '000', // Australia
    'NZ': '111', // New Zealand
    'JP': '110', // Japan
    'CN': '110', // China
    'KR': '112', // South Korea
    'SG': '999', // Singapore
    'AE': '999', // United Arab Emirates
    'BR': '190', // Brazil
    'MX': '911', // Mexico
    'ZA': '112', // South Africa
    'DE': '112', // Germany (EU Universal 112)
    'FR': '112', // France
    'IT': '112', // Italy
    'ES': '112', // Spain
    'NL': '112', // Netherlands
    'SE': '112', // Sweden
    'NO': '112', // Norway
    'CH': '112', // Switzerland
    'AT': '112', // Austria
    'BE': '112', // Belgium
    'DK': '112', // Denmark
    'FI': '112', // Finland
    'IE': '112', // Ireland
    'PT': '112', // Portugal
    'GR': '112', // Greece
    'PL': '112', // Poland
    'RU': '112', // Russia
    'TR': '112', // Turkey
  };

  /// Country ISO code -> Detailed service numbers (police, fire, ambulance, medical, universal)
  static const Map<String, Map<String, String>> _countryServiceNumbers = {
    'IN': {
      'police': '100',
      'fire': '101',
      'ambulance': '102',
      'medical': '108',
      'traffic': '103',
      'disaster': '1096',
      'child': '1098',
      'universal': '112',
    },
    'US': {
      'police': '911',
      'fire': '911',
      'ambulance': '911',
      'universal': '911',
    },
    'CA': {
      'police': '911',
      'fire': '911',
      'ambulance': '911',
      'universal': '911',
    },
    'GB': {
      'police': '999',
      'fire': '999',
      'ambulance': '999',
      'universal': '999',
    },
    'UK': {
      'police': '999',
      'fire': '999',
      'ambulance': '999',
      'universal': '999',
    },
    'AU': {
      'police': '000',
      'fire': '000',
      'ambulance': '000',
      'universal': '000',
    },
    'NZ': {
      'police': '111',
      'fire': '111',
      'ambulance': '111',
      'universal': '111',
    },
    'JP': {
      'police': '110',
      'fire': '119',
      'ambulance': '119',
      'universal': '110',
    },
    'CN': {
      'police': '110',
      'fire': '119',
      'ambulance': '120',
      'universal': '110',
    },
    'DE': {
      'police': '110',
      'fire': '112',
      'ambulance': '112',
      'universal': '112',
    },
  };

  /// GSM International Universal Emergency Standard fallback number.
  static const String defaultEmergencyNumber = '112';

  /// Resolves the primary universal emergency number for a country code, locale, or address.
  static String resolveNumber({String? countryCode, String? localeName, String? address}) {
    if (countryCode != null && countryCode.isNotEmpty) {
      final code = countryCode.toUpperCase().trim();
      if (_countryEmergencyNumbers.containsKey(code)) {
        return _countryEmergencyNumbers[code]!;
      }
    }

    if (address != null && address.isNotEmpty) {
      final addrUpper = address.toUpperCase();
      if (addrUpper.contains('INDIA') ||
          addrUpper.contains('TELANGANA') ||
          addrUpper.contains('HYDERABAD') ||
          addrUpper.contains('DELHI') ||
          addrUpper.contains('MUMBAI') ||
          addrUpper.contains('BENGALURU') ||
          addrUpper.contains('BANGALORE')) {
        return _countryEmergencyNumbers['IN']!; // 112
      } else if (addrUpper.contains('UNITED STATES') || addrUpper.contains('USA')) {
        return _countryEmergencyNumbers['US']!; // 911
      } else if (addrUpper.contains('UNITED KINGDOM') || addrUpper.contains('LONDON') || addrUpper.contains('ENGLAND')) {
        return _countryEmergencyNumbers['GB']!; // 999
      }
    }

    if (localeName != null && localeName.isNotEmpty) {
      final parts = localeName.split(RegExp(r'[_-]'));
      if (parts.length > 1) {
        final code = parts.last.toUpperCase().trim();
        if (_countryEmergencyNumbers.containsKey(code)) {
          return _countryEmergencyNumbers[code]!;
        }
      }
    }

    // Attempt system locale resolution
    try {
      if (!kIsWeb) {
        final systemLocale = Platform.localeName; // e.g. "en_IN"
        final parts = systemLocale.split(RegExp(r'[_-]'));
        if (parts.length > 1) {
          final code = parts.last.toUpperCase().trim();
          if (_countryEmergencyNumbers.containsKey(code)) {
            return _countryEmergencyNumbers[code]!;
          }
        }
      }
    } catch (e) {
      appLogger.warning('EmergencyNumberResolver: Failed to parse system locale: $e');
    }

    return defaultEmergencyNumber;
  }

  /// Resolves the specific service number for a category and country/locale.
  static String resolveServiceNumber({
    required String category,
    String? countryCode,
    String? localeName,
  }) {
    // Determine the service key based on the category title
    final cleanCategory = category.toLowerCase().trim();
    String serviceKey = 'universal';
    
    if (cleanCategory.contains('medical') || cleanCategory.contains('ambulance') || cleanCategory.contains('accident') || cleanCategory.contains('injury')) {
      serviceKey = 'ambulance';
    } else if (cleanCategory.contains('police') || cleanCategory.contains('personal') || cleanCategory.contains('safety') || cleanCategory.contains('threat') || cleanCategory.contains('violence')) {
      serviceKey = 'police';
    } else if (cleanCategory.contains('fire') || cleanCategory.contains('hazard') || cleanCategory.contains('gas')) {
      serviceKey = 'fire';
    } else if (cleanCategory.contains('disaster') || cleanCategory.contains('natural')) {
      serviceKey = 'disaster';
    }

    // Resolve country code
    String resolvedCountry = 'IN'; // Fallback default
    if (countryCode != null && countryCode.isNotEmpty) {
      resolvedCountry = countryCode.toUpperCase().trim();
    } else {
      // Check localeName
      final checkLocale = localeName ?? (kIsWeb ? null : Platform.localeName);
      if (checkLocale != null && checkLocale.isNotEmpty) {
        final parts = checkLocale.split(RegExp(r'[_-]'));
        if (parts.length > 1) {
          resolvedCountry = parts.last.toUpperCase().trim();
        }
      }
    }

    // Lookup service number
    if (_countryServiceNumbers.containsKey(resolvedCountry)) {
      final numbers = _countryServiceNumbers[resolvedCountry]!;
      if (numbers.containsKey(serviceKey)) {
        return numbers[serviceKey]!;
      }
    }

    // Fallback to the country's primary universal number
    return resolveNumber(countryCode: resolvedCountry);
  }

  /// Places a direct phone call to the emergency phone number.
  static Future<bool> makeEmergencyCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      appLogger.info('EmergencyNumberResolver: Initiating emergency phone call to $cleanNumber');
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        appLogger.error('EmergencyNumberResolver: Cannot launch phone call URI: $phoneUri');
        return false;
      }
    } catch (e, st) {
      appLogger.error('EmergencyNumberResolver: Error placing emergency call', e, st);
      return false;
    }
  }
}
