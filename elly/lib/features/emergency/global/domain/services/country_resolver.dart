/// country_resolver.dart
///
/// Priority-based country detection engine resolving regional context via GPS, Mobile Network, SIM, Locale, or Manual Override.

library;

import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';
import 'package:elly/features/emergency/global/domain/entities/country_detection_result.dart';
import 'package:elly/features/emergency/global/domain/entities/emergency_service_directory.dart';
import 'package:elly/features/emergency/global/domain/entities/country_profile.dart';

class CountryResolver {
  /// Resolves the current country based on available telemetry, locale, or manual overrides.
  static CountryDetectionResult resolve({
    TelemetryPoint? location,
    String? locale,
    String? manualOverrideCode,
  }) {
    final now = AppClock.now();

    // 1. Manual Override (Confidence 100%)
    if (manualOverrideCode != null && manualOverrideCode.isNotEmpty) {
      return CountryDetectionResult(
        countryCode: manualOverrideCode.toUpperCase(),
        confidence: 1.0,
        source: DetectionSource.manualOverride,
        timestamp: now,
      );
    }

    // 2. GPS Location Bounds Detection (Confidence 95%)
    if (location != null) {
      final code = _detectCountryFromCoordinates(location.latitude, location.longitude);
      if (code != null) {
        return CountryDetectionResult(
          countryCode: code,
          confidence: 0.95,
          source: DetectionSource.gps,
          timestamp: now,
        );
      }
    }

    // 3. System Locale (Confidence 60%)
    if (locale != null && locale.contains('_')) {
      final parts = locale.split('_');
      if (parts.length > 1 && parts[1].length == 2) {
        return CountryDetectionResult(
          countryCode: parts[1].toUpperCase(),
          confidence: 0.60,
          source: DetectionSource.locale,
          timestamp: now,
        );
      }
    }

    // 4. Default Fallback (India - IN) (Confidence 50%)
    return CountryDetectionResult(
      countryCode: 'IN',
      confidence: 0.50,
      source: DetectionSource.locale,
      timestamp: now,
    );
  }

  /// Simple latitude/longitude bounding box estimator for major global regions.
  static String? _detectCountryFromCoordinates(double lat, double lng) {
    // India Bounding Box: Lat 8.0 to 37.0, Lng 68.0 to 97.0
    if (lat >= 8.0 && lat <= 37.0 && lng >= 68.0 && lng <= 97.0) {
      return 'IN';
    }
    // US Bounding Box: Lat 24.0 to 49.0, Lng -125.0 to -66.0
    if (lat >= 24.0 && lat <= 49.0 && lng >= -125.0 && lng <= -66.0) {
      return 'US';
    }
    // EU Bounding Box: Lat 36.0 to 71.0, Lng -10.0 to 40.0
    if (lat >= 36.0 && lat <= 71.0 && lng >= -10.0 && lng <= 40.0) {
      return 'GB'; // Europe / UK regional default
    }
    // Australia Bounding Box: Lat -44.0 to -10.0, Lng 112.0 to 154.0
    if (lat >= -44.0 && lat <= -10.0 && lng >= 112.0 && lng <= 154.0) {
      return 'AU';
    }
    return null;
  }

  static CountryProfile getProfileForResult(CountryDetectionResult result) {
    return EmergencyServiceDirectory.getProfile(result.countryCode);
  }
}
