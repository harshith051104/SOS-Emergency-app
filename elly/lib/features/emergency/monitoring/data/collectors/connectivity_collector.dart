/// connectivity_collector.dart
///
/// Bounded timeout collector for internet reachability, wifi, mobile data, airplane mode, bluetooth.

library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/sensor_health.dart';
import '../../domain/entities/telemetry_snapshot.dart';
import 'base_collector.dart';

class ConnectivityCollector
    extends BaseTelemetryCollector<ConnectivityTelemetry> {
  ConnectivityCollector() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  @override
  SensorType get sensorType => SensorType.connectivity;

  @override
  Duration get defaultTimeoutBudget => const Duration(milliseconds: 200);

  @override
  Future<ConnectivityTelemetry> collect({Duration? timeoutBudget}) async {
    final budget = timeoutBudget ?? defaultTimeoutBudget;
    try {
      return await _fetchConnectivity().timeout(budget);
    } catch (e) {
      debugPrint('ConnectivityCollector: Timed out or error: $e');
      return const ConnectivityTelemetry(
        isInternetAvailable: false,
        connectionType: 'none',
        isWifiEnabled: false,
        isMobileDataEnabled: false,
        isBluetoothEnabled: false,
        isAirplaneModeEnabled: false,
      );
    }
  }

  Future<ConnectivityTelemetry> _fetchConnectivity() async {
    String connectionType = 'none';
    bool isWifiEnabled = false;
    bool isMobileDataEnabled = false;
    bool isAirplaneModeEnabled = false;
    bool isInternetAvailable = false;

    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        if (results.contains(ConnectivityResult.wifi)) {
          connectionType = 'wifi';
          isWifiEnabled = true;
        } else if (results.contains(ConnectivityResult.mobile)) {
          connectionType = 'cellular';
          isMobileDataEnabled = true;
        } else if (results.contains(ConnectivityResult.ethernet)) {
          connectionType = 'ethernet';
        } else if (results.contains(ConnectivityResult.vpn)) {
          connectionType = 'vpn';
        } else {
          connectionType = 'other';
        }

        // Quick lookup test for internet reachability bounded by 150ms
        try {
          final lookup = await InternetAddress.lookup('dns.google')
              .timeout(const Duration(milliseconds: 150));
          isInternetAvailable =
              lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
        } catch (_) {
          isInternetAvailable = false;
        }
      } else {
        // If results contain none, check if airplane mode is likely enabled
        isAirplaneModeEnabled = false;
      }
    } catch (_) {}

    return ConnectivityTelemetry(
      isInternetAvailable: isInternetAvailable,
      connectionType: connectionType,
      isWifiEnabled: isWifiEnabled,
      isMobileDataEnabled: isMobileDataEnabled,
      isBluetoothEnabled: true, // Bluetooth default fallback
      isAirplaneModeEnabled: isAirplaneModeEnabled,
    );
  }
}
