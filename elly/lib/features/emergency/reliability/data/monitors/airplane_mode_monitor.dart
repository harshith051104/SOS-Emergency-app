/// airplane_mode_monitor.dart
///
/// Monitor specifically detecting Airplane Mode state transitions.

library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class AirplaneModeMonitor {
  AirplaneModeMonitor() : _connectivity = Connectivity();

  final Connectivity _connectivity;
  bool _isAirplaneMode = false;

  bool get isAirplaneMode => _isAirplaneMode;

  Future<bool> checkAirplaneMode() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isAirplaneMode = results.contains(ConnectivityResult.none) || results.isEmpty;
      return _isAirplaneMode;
    } catch (_) {
      return false;
    }
  }
}
