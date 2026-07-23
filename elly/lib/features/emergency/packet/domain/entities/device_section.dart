/// device_section.dart
///
/// Part of the versioned Emergency Data Packet.
/// Contains device diagnostics, OS info, battery status, and localizations.

library;

import 'package:equatable/equatable.dart';

class DeviceSection extends Equatable {
  const DeviceSection({
    required this.batteryPercent,
    required this.isCharging,
    required this.connectionType,
    required this.isInternetAvailable,
    required this.platform,
    required this.deviceName,
    required this.osVersion,
    required this.isScreenLocked,
    required this.isBatterySaverEnabled,
    required this.isLowPowerMode,
    required this.timeZone,
    required this.locale,
  });

  /// Battery level percentage (e.g. 84).
  final int batteryPercent;

  /// Whether the device is currently plugged into charger.
  final bool isCharging;

  /// Network connection type (e.g. "wifi", "cellular", "none").
  final String connectionType;

  /// Whether the internet connectivity is fully validated as working.
  final bool isInternetAvailable;

  /// Operating system platform ("Android" or "iOS").
  final String platform;

  /// Marketing name of device (e.g. "Galaxy S20 FE").
  final String deviceName;

  /// Operating system version (e.g. "Android 13").
  final String osVersion;

  /// Whether the screen was locked when SOS was triggered.
  final bool isScreenLocked;

  /// Whether the device is in battery saver/restricted mode.
  final bool isBatterySaverEnabled;

  /// Whether the platform-specific low power mode is active.
  final bool isLowPowerMode;

  /// Device timezone string (e.g. "Asia/Kolkata").
  final String timeZone;

  /// Device selected locale identifier (e.g. "en_IN").
  final String locale;

  DeviceSection copyWith({
    int? batteryPercent,
    bool? isCharging,
    String? connectionType,
    bool? isInternetAvailable,
    String? platform,
    String? deviceName,
    String? osVersion,
    bool? isScreenLocked,
    bool? isBatterySaverEnabled,
    bool? isLowPowerMode,
    String? timeZone,
    String? locale,
  }) {
    return DeviceSection(
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isCharging: isCharging ?? this.isCharging,
      connectionType: connectionType ?? this.connectionType,
      isInternetAvailable: isInternetAvailable ?? this.isInternetAvailable,
      platform: platform ?? this.platform,
      deviceName: deviceName ?? this.deviceName,
      osVersion: osVersion ?? this.osVersion,
      isScreenLocked: isScreenLocked ?? this.isScreenLocked,
      isBatterySaverEnabled: isBatterySaverEnabled ?? this.isBatterySaverEnabled,
      isLowPowerMode: isLowPowerMode ?? this.isLowPowerMode,
      timeZone: timeZone ?? this.timeZone,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [
        batteryPercent,
        isCharging,
        connectionType,
        isInternetAvailable,
        platform,
        deviceName,
        osVersion,
        isScreenLocked,
        isBatterySaverEnabled,
        isLowPowerMode,
        timeZone,
        locale,
      ];
}
