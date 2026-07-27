/// connectivity_repository_impl.dart
///
/// Implementation of IConnectivityRepository.

library;

import '../../domain/entities/connectivity_state.dart';
import '../../domain/entities/network_quality.dart';
import '../../domain/entities/network_capability_matrix.dart';
import '../../domain/repositories/i_connectivity_repository.dart';
import '../monitors/connectivity_monitor.dart';
import '../monitors/network_quality_monitor.dart';

class ConnectivityRepositoryImpl implements IConnectivityRepository {
  ConnectivityRepositoryImpl({
    required ConnectivityMonitor connectivityMonitor,
    required NetworkQualityMonitor qualityMonitor,
  })  : _connectivityMonitor = connectivityMonitor,
        _qualityMonitor = qualityMonitor;

  final ConnectivityMonitor _connectivityMonitor;
  final NetworkQualityMonitor _qualityMonitor;

  @override
  Stream<ConnectivityState> get connectivityStream => _connectivityMonitor.connectivityStream;

  @override
  Stream<NetworkQuality> get qualityStream => _qualityMonitor.qualityStream;

  @override
  Stream<NetworkCapabilityMatrix> get capabilityStream => _qualityMonitor.capabilityStream;

  @override
  ConnectivityState get currentState => _connectivityMonitor.currentState;

  @override
  NetworkQuality get currentQuality => _qualityMonitor.currentQuality;

  @override
  NetworkCapabilityMatrix get currentCapabilities => _qualityMonitor.currentCapabilities;

  @override
  Future<void> checkConnectivityNow() async {
    await _connectivityMonitor.checkConnectivityNow();
    await _qualityMonitor.probeNetwork();
  }
}
