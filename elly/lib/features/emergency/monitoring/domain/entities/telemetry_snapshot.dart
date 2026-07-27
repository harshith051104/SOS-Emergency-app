/// telemetry_snapshot.dart
///
/// Comprehensive immutable multi-sensor telemetry collection snapshot.

library;

import 'package:equatable/equatable.dart';
import 'sensor_health.dart';
import 'telemetry_confidence.dart';
import 'emergency_severity.dart';

class LocationTelemetry extends Equatable {
  const LocationTelemetry({
    this.latitude,
    this.longitude,
    this.altitude,
    required this.accuracy,
    this.speed,
    this.heading,
    required this.address,
    required this.timestamp,
    required this.isGpsEnabled,
    this.isMockLocation = false,
    this.isoCountryCode,
  });

  final double? latitude;
  final double? longitude;
  final double? altitude;
  final String accuracy;
  final double? speed;
  final double? heading;
  final String address;
  final DateTime timestamp;
  final bool isGpsEnabled;
  final bool isMockLocation;
  final String? isoCountryCode;

  bool get hasValidCoordinates => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        altitude,
        accuracy,
        speed,
        heading,
        address,
        timestamp,
        isGpsEnabled,
        isMockLocation,
        isoCountryCode,
      ];
}

class DeviceTelemetry extends Equatable {
  const DeviceTelemetry({
    required this.batteryPercent,
    required this.isCharging,
    this.batteryTemperatureCelsius,
    required this.isBatterySaverEnabled,
    required this.isScreenLocked,
    this.deviceOrientation = 'portrait',
    required this.deviceName,
    required this.osVersion,
    required this.platform,
    required this.timeZone,
    required this.locale,
  });

  final int batteryPercent;
  final bool isCharging;
  final double? batteryTemperatureCelsius;
  final bool isBatterySaverEnabled;
  final bool isScreenLocked;
  final String deviceOrientation;
  final String deviceName;
  final String osVersion;
  final String platform;
  final String timeZone;
  final String locale;

  @override
  List<Object?> get props => [
        batteryPercent,
        isCharging,
        batteryTemperatureCelsius,
        isBatterySaverEnabled,
        isScreenLocked,
        deviceOrientation,
        deviceName,
        osVersion,
        platform,
        timeZone,
        locale,
      ];
}

class ConnectivityTelemetry extends Equatable {
  const ConnectivityTelemetry({
    required this.isInternetAvailable,
    required this.connectionType,
    required this.isWifiEnabled,
    required this.isMobileDataEnabled,
    required this.isBluetoothEnabled,
    required this.isAirplaneModeEnabled,
    this.signalStrengthDbm,
  });

  final bool isInternetAvailable;
  final String connectionType;
  final bool isWifiEnabled;
  final bool isMobileDataEnabled;
  final bool isBluetoothEnabled;
  final bool isAirplaneModeEnabled;
  final int? signalStrengthDbm;

  @override
  List<Object?> get props => [
        isInternetAvailable,
        connectionType,
        isWifiEnabled,
        isMobileDataEnabled,
        isBluetoothEnabled,
        isAirplaneModeEnabled,
        signalStrengthDbm,
      ];
}

class ApplicationTelemetry extends Equatable {
  const ApplicationTelemetry({
    required this.isForeground,
    required this.lastUserInteraction,
    required this.sessionDuration,
    required this.appVersion,
  });

  final bool isForeground;
  final DateTime lastUserInteraction;
  final Duration sessionDuration;
  final String appVersion;

  @override
  List<Object?> get props => [
        isForeground,
        lastUserInteraction,
        sessionDuration,
        appVersion,
      ];
}

class MotionTelemetry extends Equatable {
  const MotionTelemetry({
    required this.motionState,
    this.confidenceScore = 100,
    this.stepCount,
  });

  /// Motion state: 'stationary', 'walking', 'running', 'vehicle', 'unknown'
  final String motionState;
  final int confidenceScore;
  final int? stepCount;

  @override
  List<Object?> get props => [motionState, confidenceScore, stepCount];
}

class HealthTelemetry extends Equatable {
  const HealthTelemetry({
    this.heartRateBpm,
    this.bloodOxygenPercent,
    this.systolicBloodPressure,
    this.diastolicBloodPressure,
    this.glucoseMgDl,
    this.isSmartwatchConnected = false,
    this.smartwatchName,
  });

  final int? heartRateBpm;
  final int? bloodOxygenPercent;
  final int? systolicBloodPressure;
  final int? diastolicBloodPressure;
  final double? glucoseMgDl;
  final bool isSmartwatchConnected;
  final String? smartwatchName;

  @override
  List<Object?> get props => [
        heartRateBpm,
        bloodOxygenPercent,
        systolicBloodPressure,
        diastolicBloodPressure,
        glucoseMgDl,
        isSmartwatchConnected,
        smartwatchName,
      ];
}

class TelemetrySnapshot extends Equatable {
  const TelemetrySnapshot({
    required this.utcTime,
    required this.localTime,
    required this.monotonicElapsedMs,
    required this.location,
    required this.device,
    required this.connectivity,
    required this.application,
    required this.motion,
    required this.health,
    required this.confidence,
    required this.severity,
    required this.sensorHealthMap,
  });

  final DateTime utcTime;
  final DateTime localTime;
  final int monotonicElapsedMs;

  final LocationTelemetry location;
  final DeviceTelemetry device;
  final ConnectivityTelemetry connectivity;
  final ApplicationTelemetry application;
  final MotionTelemetry motion;
  final HealthTelemetry health;

  final TelemetryConfidence confidence;
  final EmergencySeverity severity;
  final Map<SensorType, SensorHealth> sensorHealthMap;

  @override
  List<Object?> get props => [
        utcTime,
        localTime,
        monotonicElapsedMs,
        location,
        device,
        connectivity,
        application,
        motion,
        health,
        confidence,
        severity,
        sensorHealthMap,
      ];
}
