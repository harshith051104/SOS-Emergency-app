/// network_quality.dart
///
/// Domain entity evaluating network link quality rating.

library;

import 'package:equatable/equatable.dart';

enum NetworkQualityTier {
  excellent,
  good,
  fair,
  poor,
  offline,
}

class NetworkQuality extends Equatable {
  const NetworkQuality({
    required this.tier,
    required this.latencyMs,
    required this.packetLossPercent,
  });

  final NetworkQualityTier tier;
  final int latencyMs;
  final double packetLossPercent;

  factory NetworkQuality.offline() {
    return const NetworkQuality(
      tier: NetworkQualityTier.offline,
      latencyMs: -1,
      packetLossPercent: 100.0,
    );
  }

  @override
  List<Object?> get props => [tier, latencyMs, packetLossPercent];
}
