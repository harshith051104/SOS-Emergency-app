/// disconnect_info.dart
///
/// Domain entity logging abrupt disconnect / shutdown details.

library;

import 'package:equatable/equatable.dart';

class DisconnectInfo extends Equatable {
  const DisconnectInfo({
    required this.timestamp,
    required this.reason,
    required this.lastKnownBattery,
    this.lastKnownCoordinates,
    required this.pendingQueueSize,
  });

  final DateTime timestamp;
  final String reason;
  final int lastKnownBattery;
  final String? lastKnownCoordinates;
  final int pendingQueueSize;

  @override
  List<Object?> get props => [
        timestamp,
        reason,
        lastKnownBattery,
        lastKnownCoordinates,
        pendingQueueSize,
      ];
}
