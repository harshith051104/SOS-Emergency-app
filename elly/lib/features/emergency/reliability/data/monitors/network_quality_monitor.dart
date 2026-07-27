/// network_quality_monitor.dart
///
/// Monitor classifying round-trip latency and constructing NetworkCapabilityMatrix.

library;

import 'dart:async';
import 'dart:io';
import '../../domain/entities/network_quality.dart';

import '../../domain/entities/network_capability_matrix.dart';

class NetworkQualityMonitor {
  NetworkQualityMonitor()
      : _qualityController = StreamController<NetworkQuality>.broadcast(),
        _capabilityController = StreamController<NetworkCapabilityMatrix>.broadcast();

  final StreamController<NetworkQuality> _qualityController;
  final StreamController<NetworkCapabilityMatrix> _capabilityController;
  Timer? _probeTimer;

  NetworkQuality _currentQuality = NetworkQuality.offline();
  NetworkCapabilityMatrix _currentCapabilities = NetworkCapabilityMatrix.offline();

  Stream<NetworkQuality> get qualityStream => _qualityController.stream;
  Stream<NetworkCapabilityMatrix> get capabilityStream => _capabilityController.stream;

  NetworkQuality get currentQuality => _currentQuality;
  NetworkCapabilityMatrix get currentCapabilities => _currentCapabilities;

  void startProbing({Duration interval = const Duration(seconds: 15)}) {
    _probeTimer?.cancel();
    _probeTimer = Timer.periodic(interval, (_) => probeNetwork());
    probeNetwork();
  }

  Future<void> probeNetwork() async {
    final start = DateTime.now();
    bool canHttp = false;
    bool canDns = false;
    int latency = -1;

    try {
      final lookup = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(milliseconds: 1200));
      if (lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty) {
        canDns = true;
        canHttp = true;
        latency = DateTime.now().difference(start).inMilliseconds;
      }
    } catch (_) {
      latency = -1;
    }

    NetworkQualityTier tier;
    if (!canHttp || latency < 0) {
      tier = NetworkQualityTier.offline;
    } else if (latency < 150) {
      tier = NetworkQualityTier.excellent;
    } else if (latency < 400) {
      tier = NetworkQualityTier.good;
    } else if (latency < 800) {
      tier = NetworkQualityTier.fair;
    } else {
      tier = NetworkQualityTier.poor;
    }

    _currentQuality = NetworkQuality(
      tier: tier,
      latencyMs: latency,
      packetLossPercent: canHttp ? 0.0 : 100.0,
    );

    _currentCapabilities = NetworkCapabilityMatrix(
      canHttp: canHttp,
      canDns: canDns,
      canTcp: canHttp,
      canUdp: canHttp,
      isCaptivePortal: false,
      canSmsFallback: true,
    );

    if (!_qualityController.isClosed) {
      Future<void>(() {
        if (!_qualityController.isClosed) _qualityController.add(_currentQuality);
        if (!_capabilityController.isClosed) _capabilityController.add(_currentCapabilities);
      });
    }
  }

  void stopProbing() {
    _probeTimer?.cancel();
    _probeTimer = null;
  }

  Future<void> dispose() async {
    stopProbing();
    await _qualityController.close();
    await _capabilityController.close();
  }
}
