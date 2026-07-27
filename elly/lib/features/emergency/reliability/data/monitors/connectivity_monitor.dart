/// connectivity_monitor.dart
///
/// Monitor querying connectivity plus and geolocator APIs to build unified ConnectivityState.

library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/connectivity_state.dart';

class ConnectivityMonitor {
  ConnectivityMonitor()
      : _connectivity = Connectivity(),
        _stateController = StreamController<ConnectivityState>.broadcast();

  final Connectivity _connectivity;
  final StreamController<ConnectivityState> _stateController;
  StreamSubscription? _connectivitySubscription;

  ConnectivityState _currentState = ConnectivityState.offline();

  Stream<ConnectivityState> get connectivityStream => _stateController.stream;
  ConnectivityState get currentState => _currentState;

  /// Starts continuous connectivity monitoring.
  void startMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _evaluateConnectivity(results);
    });
    checkConnectivityNow();
  }

  /// Forces an immediate manual check of all connectivity channels.
  Future<ConnectivityState> checkConnectivityNow() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return await _evaluateConnectivity(results);
    } catch (e) {
      debugPrint('ConnectivityMonitor: Check error: $e');
      return _currentState;
    }
  }

  Future<ConnectivityState> _evaluateConnectivity(List<ConnectivityResult> results) async {
    final bool isWifi = results.contains(ConnectivityResult.wifi);
    final bool isMobile = results.contains(ConnectivityResult.mobile);
    final bool isNone = results.contains(ConnectivityResult.none) || results.isEmpty;

    final bool isInternetAvailable = !isNone;
    bool isGpsAvailable = false;

    try {
      isGpsAvailable = await Geolocator.isLocationServiceEnabled();
    } catch (_) {}

    OverallConnectivityStatus status;
    if (isInternetAvailable) {
      status = OverallConnectivityStatus.online;
    } else if (isWifi || isMobile || isGpsAvailable) {
      status = OverallConnectivityStatus.degraded;
    } else {
      status = OverallConnectivityStatus.offline;
    }

    _currentState = ConnectivityState(
      isInternetAvailable: isInternetAvailable,
      isWifiAvailable: isWifi,
      isMobileAvailable: isMobile,
      isAirplaneModeEnabled: isNone && !isWifi && !isMobile,
      isGpsAvailable: isGpsAvailable,
      isSimAvailable: true,
      overallStatus: status,
      lastUpdated: DateTime.now(),
    );

    if (!_stateController.isClosed) {
      Future<void>(() {
        if (!_stateController.isClosed) _stateController.add(_currentState);
      });
    }

    return _currentState;
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _stateController.close();
  }
}
