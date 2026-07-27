/// i_connectivity_repository.dart
///
/// Interface for connectivity, link quality, capability matrix, and airplane mode monitoring.

library;

import '../entities/connectivity_state.dart';
import '../entities/network_quality.dart';
import '../entities/network_capability_matrix.dart';

abstract class IConnectivityRepository {
  Stream<ConnectivityState> get connectivityStream;
  Stream<NetworkQuality> get qualityStream;
  Stream<NetworkCapabilityMatrix> get capabilityStream;

  ConnectivityState get currentState;
  NetworkQuality get currentQuality;
  NetworkCapabilityMatrix get currentCapabilities;

  Future<void> checkConnectivityNow();
}
