/// cross_border_context.dart
///
/// Immutable domain state holding active global location context, home country, roaming status, and country profiles.

library;

import 'package:flutter/foundation.dart';
import 'country_profile.dart';
import 'country_detection_result.dart';

@immutable
class CrossBorderContext {
  const CrossBorderContext({
    required this.currentCountry,
    required this.homeCountry,
    this.hasBorderCrossed = false,
    this.isRoaming = false,
    this.lastDetectedAt,
    this.lastDetectionResult,
  });

  final CountryProfile currentCountry;
  final CountryProfile homeCountry;
  final bool hasBorderCrossed;
  final bool isRoaming;
  final DateTime? lastDetectedAt;
  final CountryDetectionResult? lastDetectionResult;

  CrossBorderContext copyWith({
    CountryProfile? currentCountry,
    CountryProfile? homeCountry,
    bool? hasBorderCrossed,
    bool? isRoaming,
    DateTime? lastDetectedAt,
    CountryDetectionResult? lastDetectionResult,
  }) {
    return CrossBorderContext(
      currentCountry: currentCountry ?? this.currentCountry,
      homeCountry: homeCountry ?? this.homeCountry,
      hasBorderCrossed: hasBorderCrossed ?? this.hasBorderCrossed,
      isRoaming: isRoaming ?? this.isRoaming,
      lastDetectedAt: lastDetectedAt ?? this.lastDetectedAt,
      lastDetectionResult: lastDetectionResult ?? this.lastDetectionResult,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentCountry': currentCountry.toJson(),
        'homeCountry': homeCountry.toJson(),
        'hasBorderCrossed': hasBorderCrossed,
        'isRoaming': isRoaming,
        'lastDetectedAt': lastDetectedAt?.toIso8601String(),
        'lastDetectionResult': lastDetectionResult?.toJson(),
      };
}
