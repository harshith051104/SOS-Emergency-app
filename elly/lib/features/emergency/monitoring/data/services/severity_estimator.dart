/// severity_estimator.dart
///
/// Service continuously estimating situational risk severity level based on telemetry rules.

library;

import '../../domain/entities/emergency_severity.dart';
import '../../domain/entities/telemetry_snapshot.dart';

class SeverityEstimator {
  const SeverityEstimator();

  EmergencySeverity estimate({
    required LocationTelemetry location,
    required DeviceTelemetry device,
    required ConnectivityTelemetry connectivity,
    required MotionTelemetry motion,
  }) {
    int score = 40; // Base score for active SOS
    final factors = <String>['Active SOS Emergency'];

    // 1. Low Battery check
    if (device.batteryPercent <= 10) {
      score += 25;
      factors.add('Critical Battery (${device.batteryPercent}%)');
    } else if (device.batteryPercent <= 20) {
      score += 15;
      factors.add('Low Battery (${device.batteryPercent}%)');
    }

    // 2. Internet connectivity loss
    if (!connectivity.isInternetAvailable) {
      score += 20;
      factors.add('Internet Unavailable');
    }

    // 3. Airplane mode enabled
    if (connectivity.isAirplaneModeEnabled) {
      score += 25;
      factors.add('Airplane Mode Active');
    }

    // 4. GPS / Location unavailable
    if (!location.hasValidCoordinates) {
      score += 15;
      factors.add('GPS Coordinates Unavailable');
    }

    // 5. Stationary motion
    if (motion.motionState == 'stationary') {
      score += 5;
      factors.add('Device Stationary');
    }

    // 6. Night time check (between 10 PM and 6 AM)
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 6) {
      score += 10;
      factors.add('Nighttime Context');
    }

    final finalScore = score.clamp(0, 100);
    EmergencySeverityLevel level;

    if (finalScore >= 80) {
      level = EmergencySeverityLevel.critical;
    } else if (finalScore >= 60) {
      level = EmergencySeverityLevel.high;
    } else if (finalScore >= 40) {
      level = EmergencySeverityLevel.medium;
    } else {
      level = EmergencySeverityLevel.low;
    }

    return EmergencySeverity(
      level: level,
      score: finalScore,
      contributingFactors: factors,
    );
  }
}
