/// device_collector.dart
///
/// Bounded timeout collector for battery state, screen state, and device metadata.

library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../domain/entities/sensor_health.dart';
import '../../domain/entities/telemetry_snapshot.dart';
import 'base_collector.dart';

class DeviceCollector extends BaseTelemetryCollector<DeviceTelemetry> {
  DeviceCollector()
      : _battery = Battery(),
        _deviceInfo = DeviceInfoPlugin();

  final Battery _battery;
  final DeviceInfoPlugin _deviceInfo;

  @override
  SensorType get sensorType => SensorType.device;

  @override
  Duration get defaultTimeoutBudget => const Duration(milliseconds: 100);

  @override
  Future<DeviceTelemetry> collect({Duration? timeoutBudget}) async {
    final budget = timeoutBudget ?? defaultTimeoutBudget;
    try {
      return await _fetchDeviceStats().timeout(budget);
    } catch (e) {
      debugPrint('DeviceCollector: Timed out or error: $e');
      return DeviceTelemetry(
        batteryPercent: 100,
        isCharging: false,
        isBatterySaverEnabled: false,
        isScreenLocked: false,
        deviceName: 'Generic Device',
        osVersion: 'Unknown OS',
        platform: kIsWeb ? 'Web' : (Platform.isAndroid ? 'Android' : 'iOS'),
        timeZone: 'UTC',
        locale: 'en',
      );
    }
  }

  Future<DeviceTelemetry> _fetchDeviceStats() async {
    int batteryPercent = 100;
    bool isCharging = false;
    bool isBatterySaverEnabled = false;

    try {
      batteryPercent = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      isCharging = state == BatteryState.charging || state == BatteryState.full;
      isBatterySaverEnabled = await _battery.isInBatterySaveMode;
    } catch (_) {}

    final String platform = kIsWeb ? 'Web' : (Platform.isAndroid ? 'Android' : 'iOS');
    String deviceName = kIsWeb ? 'Web Browser' : 'Generic Device';
    String osVersion = kIsWeb ? 'Web Platform' : 'Unknown OS';

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceName = webInfo.browserName.name;
        osVersion = webInfo.userAgent ?? 'Web Browser';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        osVersion = 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceName = iosInfo.name;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }
    } catch (_) {}

    String timeZone = 'UTC';
    String locale = 'en_US';
    try {
      timeZone = DateTime.now().timeZoneName;
      if (!kIsWeb) {
        locale = Platform.localeName;
      }
    } catch (_) {}


    return DeviceTelemetry(
      batteryPercent: batteryPercent,
      isCharging: isCharging,
      isBatterySaverEnabled: isBatterySaverEnabled,
      isScreenLocked: false,
      deviceName: deviceName,
      osVersion: osVersion,
      platform: platform,
      timeZone: timeZone,
      locale: locale,
    );
  }
}
