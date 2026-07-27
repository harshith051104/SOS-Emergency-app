/// network_capability_matrix.dart
///
/// Domain entity exposing detailed network channel capability flags.

library;

import 'package:equatable/equatable.dart';

class NetworkCapabilityMatrix extends Equatable {
  const NetworkCapabilityMatrix({
    required this.canHttp,
    required this.canDns,
    required this.canTcp,
    required this.canUdp,
    required this.isCaptivePortal,
    required this.canSmsFallback,
  });

  final bool canHttp;
  final bool canDns;
  final bool canTcp;
  final bool canUdp;
  final bool isCaptivePortal;
  final bool canSmsFallback;

  factory NetworkCapabilityMatrix.fullOnline() {
    return const NetworkCapabilityMatrix(
      canHttp: true,
      canDns: true,
      canTcp: true,
      canUdp: true,
      isCaptivePortal: false,
      canSmsFallback: true,
    );
  }

  factory NetworkCapabilityMatrix.offline() {
    return const NetworkCapabilityMatrix(
      canHttp: false,
      canDns: false,
      canTcp: false,
      canUdp: false,
      isCaptivePortal: false,
      canSmsFallback: true,
    );
  }

  @override
  List<Object?> get props => [
        canHttp,
        canDns,
        canTcp,
        canUdp,
        isCaptivePortal,
        canSmsFallback,
      ];
}
