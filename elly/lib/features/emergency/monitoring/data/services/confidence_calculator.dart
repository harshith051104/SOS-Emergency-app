/// confidence_calculator.dart
///
/// Service calculating per-component and aggregate telemetry confidence scores.

library;

import '../../domain/entities/telemetry_confidence.dart';
import '../../domain/entities/telemetry_snapshot.dart';
import '../../domain/entities/sensor_health.dart';

class ConfidenceCalculator {
  const ConfidenceCalculator();

  TelemetryConfidence calculate({
    required LocationTelemetry location,
    required DeviceTelemetry device,
    required ConnectivityTelemetry connectivity,
    required MotionTelemetry motion,
    required HealthTelemetry health,
    required Map<SensorType, SensorHealth> sensorHealthMap,
  }) {
    // 1. Location Confidence
    int locConf = 0;
    if (location.hasValidCoordinates) {
      locConf = 90;
      if (location.isGpsEnabled) locConf += 10;
      if (location.isMockLocation) locConf -= 40;
    } else {
      locConf = location.isGpsEnabled ? 20 : 0;
    }
    locConf = locConf.clamp(0, 100);

    // 2. Network Confidence
    int netConf = 0;
    if (connectivity.isInternetAvailable) {
      netConf = 100;
    } else if (connectivity.isWifiEnabled || connectivity.isMobileDataEnabled) {
      netConf = 60;
    } else if (connectivity.isAirplaneModeEnabled) {
      netConf = 10;
    } else {
      netConf = 30;
    }
    netConf = netConf.clamp(0, 100);

    // 3. Motion Confidence
    final int motionConf = motion.confidenceScore.clamp(0, 100);

    // 4. Battery Confidence
    int batConf = 100;
    final batHealth = sensorHealthMap[SensorType.device];
    if (batHealth != null && batHealth.status == SensorHealthStatus.degraded) {
      batConf = 70;
    } else if (batHealth != null &&
        batHealth.status == SensorHealthStatus.unavailable) {
      batConf = 30;
    }

    // 5. Health Confidence
    int healthConf = 0;
    if (health.isSmartwatchConnected) {
      healthConf = 95;
    } else {
      healthConf = 0;
    }

    // 6. Overall Aggregated Confidence
    final overall = ((locConf * 0.40) +
            (netConf * 0.30) +
            (batConf * 0.15) +
            (motionConf * 0.15))
        .round()
        .clamp(0, 100);

    return TelemetryConfidence(
      locationConfidence: locConf,
      networkConfidence: netConf,
      motionConfidence: motionConf,
      batteryConfidence: batConf,
      healthConfidence: healthConf,
      overallConfidence: overall,
    );
  }
}
