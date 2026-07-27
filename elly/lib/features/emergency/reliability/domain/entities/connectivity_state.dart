/// connectivity_state.dart
///
/// Unified connectivity state domain entity.

library;

import 'package:equatable/equatable.dart';

enum OverallConnectivityStatus {
  online,
  degraded,
  offline,
}

class ConnectivityState extends Equatable {
  const ConnectivityState({
    required this.isInternetAvailable,
    required this.isWifiAvailable,
    required this.isMobileAvailable,
    required this.isAirplaneModeEnabled,
    required this.isGpsAvailable,
    required this.isSimAvailable,
    required this.overallStatus,
    required this.lastUpdated,
  });

  final bool isInternetAvailable;
  final bool isWifiAvailable;
  final bool isMobileAvailable;
  final bool isAirplaneModeEnabled;
  final bool isGpsAvailable;
  final bool isSimAvailable;
  final OverallConnectivityStatus overallStatus;
  final DateTime lastUpdated;

  factory ConnectivityState.offline() {
    return ConnectivityState(
      isInternetAvailable: false,
      isWifiAvailable: false,
      isMobileAvailable: false,
      isAirplaneModeEnabled: false,
      isGpsAvailable: false,
      isSimAvailable: true,
      overallStatus: OverallConnectivityStatus.offline,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        isInternetAvailable,
        isWifiAvailable,
        isMobileAvailable,
        isAirplaneModeEnabled,
        isGpsAvailable,
        isSimAvailable,
        overallStatus,
        lastUpdated,
      ];
}
