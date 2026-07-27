/// country_profile.dart
///
/// Immutable domain model representing regional emergency numbers, region profiles, embassy hotlines,
/// directory versioning, and communication capabilities.

library;

import 'package:flutter/foundation.dart';
import 'communication_capabilities.dart';

@immutable
class EmbassyContact {
  const EmbassyContact({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
  });

  final String name;
  final String phone;
  final String address;
  final String city;

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'address': address,
        'city': city,
      };

  factory EmbassyContact.fromJson(Map<String, dynamic> json) => EmbassyContact(
        name: json['name'] as String,
        phone: json['phone'] as String,
        address: json['address'] as String,
        city: json['city'] as String,
      );
}

@immutable
class RegionProfile {
  const RegionProfile({
    required this.regionCode,
    required this.regionName,
    required this.medicalNumber,
    required this.policeNumber,
    required this.fireNumber,
  });

  final String regionCode;
  final String regionName;
  final String medicalNumber;
  final String policeNumber;
  final String fireNumber;

  Map<String, dynamic> toJson() => {
        'regionCode': regionCode,
        'regionName': regionName,
        'medicalNumber': medicalNumber,
        'policeNumber': policeNumber,
        'fireNumber': fireNumber,
      };

  factory RegionProfile.fromJson(Map<String, dynamic> json) => RegionProfile(
        regionCode: json['regionCode'] as String,
        regionName: json['regionName'] as String,
        medicalNumber: json['medicalNumber'] as String,
        policeNumber: json['policeNumber'] as String,
        fireNumber: json['fireNumber'] as String,
      );
}

@immutable
class CountryProfile {
  const CountryProfile({
    required this.countryCode,
    required this.countryName,
    required this.region,
    required this.defaultLanguage,
    required this.timeZone,
    required this.currency,
    required this.medicalNumber,
    required this.policeNumber,
    required this.fireNumber,
    this.disasterNumber = '112',
    this.directoryVersion = '2026.1',
    this.unitSystem = 'metric',
    this.embassyContact,
    this.regionProfiles = const [],
    this.capabilities = const CommunicationCapabilities(),
  });

  final String countryCode;
  final String countryName;
  final String region;
  final String defaultLanguage;
  final String timeZone;
  final String currency;
  final String medicalNumber;
  final String policeNumber;
  final String fireNumber;
  final String disasterNumber;
  final String directoryVersion;
  final String unitSystem;
  final EmbassyContact? embassyContact;
  final List<RegionProfile> regionProfiles;
  final CommunicationCapabilities capabilities;

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'countryName': countryName,
      'region': region,
      'defaultLanguage': defaultLanguage,
      'timeZone': timeZone,
      'currency': currency,
      'medicalNumber': medicalNumber,
      'policeNumber': policeNumber,
      'fireNumber': fireNumber,
      'disasterNumber': disasterNumber,
      'directoryVersion': directoryVersion,
      'unitSystem': unitSystem,
      'embassyContact': embassyContact?.toJson(),
      'regionProfiles': regionProfiles.map((r) => r.toJson()).toList(),
      'capabilities': capabilities.toJson(),
    };
  }

  factory CountryProfile.fromJson(Map<String, dynamic> json) {
    return CountryProfile(
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      region: json['region'] as String,
      defaultLanguage: json['defaultLanguage'] as String,
      timeZone: json['timeZone'] as String,
      currency: json['currency'] as String,
      medicalNumber: json['medicalNumber'] as String,
      policeNumber: json['policeNumber'] as String,
      fireNumber: json['fireNumber'] as String,
      disasterNumber: json['disasterNumber'] as String? ?? '112',
      directoryVersion: json['directoryVersion'] as String? ?? '2026.1',
      unitSystem: json['unitSystem'] as String? ?? 'metric',
      embassyContact: json['embassyContact'] != null
          ? EmbassyContact.fromJson(Map<String, dynamic>.from(json['embassyContact'] as Map))
          : null,
      regionProfiles: (json['regionProfiles'] as List<dynamic>?)
              ?.map((r) => RegionProfile.fromJson(Map<String, dynamic>.from(r as Map)))
              .toList() ??
          const [],
      capabilities: json['capabilities'] != null
          ? CommunicationCapabilities.fromJson(Map<String, dynamic>.from(json['capabilities'] as Map))
          : const CommunicationCapabilities(),
    );
  }
}
