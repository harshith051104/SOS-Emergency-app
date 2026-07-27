/// predictive_disconnect_monitor.dart
///
/// Monitor analyzing telemetry warning indicators to issue early disconnect warnings.

library;

import '../../domain/entities/network_quality.dart';


class PredictiveDisconnectMonitor {
  PredictiveDisconnectMonitor();

  bool evaluateWarning({
    required int batteryPercent,
    required NetworkQuality networkQuality,
    required int consecutiveNetworkFailures,
  }) {
    if (batteryPercent <= 12) {
      return true;
    }
    if (networkQuality.tier == NetworkQualityTier.poor && consecutiveNetworkFailures >= 2) {
      return true;
    }
    if (consecutiveNetworkFailures >= 3) {
      return true;
    }
    return false;
  }
}
