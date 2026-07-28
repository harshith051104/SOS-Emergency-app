/// device_service.dart
///
/// Gathers device telemetry, network info, battery stats, power modes,
/// locales, and platform specifics. Handles errors gracefully.

library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/device_section.dart';

class DeviceService {
  DeviceService()
      : _battery = Battery(),
        _deviceInfo = DeviceInfoPlugin(),
        _connectivity = Connectivity();

  final Battery _battery;
  final DeviceInfoPlugin _deviceInfo;
  final Connectivity _connectivity;

  /// Retrieves a snapshot of the current device status.
  Future<DeviceSection> getDeviceTelemetry() async {
    int batteryPercent = 100;
    bool isCharging = false;
    bool isBatterySaverEnabled = false;

    // 1. Gather Battery info
    try {
      batteryPercent = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      isCharging = state == BatteryState.charging || state == BatteryState.full;
      isBatterySaverEnabled = await _battery.isInBatterySaveMode;
    } catch (e) {
      debugPrint('DeviceService: Failed to retrieve battery info: $e');
    }

    // 2. Gather Connectivity info
    String connectionType = 'none';
    bool isInternetAvailable = false;
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        if (results.contains(ConnectivityResult.wifi)) {
          connectionType = 'wifi';
        } else if (results.contains(ConnectivityResult.ethernet)) {
          connectionType = 'ethernet';
        } else if (results.contains(ConnectivityResult.mobile)) {
          connectionType = 'cellular';
        } else if (results.contains(ConnectivityResult.vpn)) {
          connectionType = 'vpn';
        } else {
          connectionType = 'other';
        }

        // Test internet availability
        if (kIsWeb) {
          isInternetAvailable = true;
        } else {
          try {
            final lookup = await InternetAddress.lookup('dns.google')
                .timeout(const Duration(milliseconds: 1000));
            isInternetAvailable = lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
          } catch (_) {
            isInternetAvailable = false;
          }
        }
      }
    } catch (e) {
      debugPrint('DeviceService: Failed to retrieve connectivity: $e');
    }

    // 3. Gather Hardware and OS info
    final String platform = kIsWeb ? 'Web' : (Platform.isAndroid ? 'Android' : 'iOS');
    String deviceName = kIsWeb ? 'Web Browser' : 'Unknown Device';
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
    } catch (e) {
      debugPrint('DeviceService: Failed to retrieve device info: $e');
    }

    // 4. Timezone & Locale
    String timeZone = 'Unknown';
    String locale = 'en_US';
    try {
      timeZone = DateTime.now().timeZoneName;
      if (!kIsWeb) {
        locale = Platform.localeName;
      }
    } catch (e) {
      debugPrint('DeviceService: Failed to resolve locale/timezone: $e');
    }


    return DeviceSection(
      batteryPercent: batteryPercent,
      isCharging: isCharging,
      connectionType: connectionType,
      isInternetAvailable: isInternetAvailable,
      platform: platform,
      deviceName: deviceName,
      osVersion: osVersion,
      isScreenLocked: false, // Flutter standard API cannot determine screen lock state without native plugin integrations
      isBatterySaverEnabled: isBatterySaverEnabled,
      isLowPowerMode: isBatterySaverEnabled,
      timeZone: timeZone,
      locale: locale,
    );
  }
}
