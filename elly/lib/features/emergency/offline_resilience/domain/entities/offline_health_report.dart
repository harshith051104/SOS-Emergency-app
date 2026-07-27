/// offline_health_report.dart
///
/// Diagnostic snapshot of offline queue size, storage pressure, battery degradation, and corruption detection.

library;

import 'package:flutter/foundation.dart';
import 'resilience_policies.dart';

@immutable
class OfflineHealthReport {
  const OfflineHealthReport({
    required this.queuedPackets,
    this.oldestPacketAge,
    this.newestPacketAge,
    required this.queueSizeBytes,
    required this.storageUsagePercent,
    required this.estimatedRemainingCapacityMB,
    required this.batteryPolicy,
    required this.storagePolicy,
    required this.isCorruptionDetected,
    this.lastRecoveryAt,
  });

  final int queuedPackets;
  final Duration? oldestPacketAge;
  final Duration? newestPacketAge;
  final int queueSizeBytes;
  final double storageUsagePercent;
  final double estimatedRemainingCapacityMB;
  final BatteryPolicyState batteryPolicy;
  final StoragePolicy storagePolicy;
  final bool isCorruptionDetected;
  final DateTime? lastRecoveryAt;

  Map<String, dynamic> toJson() => {
        'queuedPackets': queuedPackets,
        'oldestPacketAgeSeconds': oldestPacketAge?.inSeconds,
        'newestPacketAgeSeconds': newestPacketAge?.inSeconds,
        'queueSizeBytes': queueSizeBytes,
        'storageUsagePercent': storageUsagePercent,
        'estimatedRemainingCapacityMB': estimatedRemainingCapacityMB,
        'batteryPolicy': batteryPolicy.name,
        'storagePolicy': storagePolicy.name,
        'isCorruptionDetected': isCorruptionDetected,
        'lastRecoveryAt': lastRecoveryAt?.toIso8601String(),
      };
}
