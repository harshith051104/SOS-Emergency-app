/// offline_health_monitor.dart
///
/// Diagnostic service continuously computing OfflineHealthReport metrics.

library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';

import 'package:elly/features/emergency/offline_resilience/domain/entities/offline_health_report.dart';
import 'package:elly/features/emergency/offline_resilience/domain/entities/resilience_policies.dart';
import 'package:elly/features/emergency/offline_resilience/domain/services/storage_manager.dart';

class OfflineHealthMonitor {
  OfflineHealthMonitor(this._ref, this._storageManager);

  final Ref _ref;
  final StorageManager _storageManager;

  OfflineHealthReport generateReport() {
    final queueService = _ref.read(offlineQueueProvider);
    final allPackets = queueService.allPackets;
    final pendingPackets = queueService.pendingPackets;

    final now = AppClock.now();
    Duration? oldestAge;
    Duration? newestAge;

    int totalBytes = 0;
    for (final item in allPackets) {
      totalBytes += jsonEncode(item.toJson()).length;
    }

    if (allPackets.isNotEmpty) {
      oldestAge = now.difference(allPackets.first.createdAt);
      newestAge = now.difference(allPackets.last.createdAt);
    }

    final storagePolicy = _storageManager.evaluateStoragePolicy();

    const batteryLevel = 85;
    BatteryPolicyState batteryPolicy = BatteryPolicyState.normal;
    if (batteryLevel < 20) {
      batteryPolicy = BatteryPolicyState.critical;
    } else if (batteryLevel <= 50) {
      batteryPolicy = BatteryPolicyState.low;
    }

    return OfflineHealthReport(
      queuedPackets: pendingPackets.length,
      oldestPacketAge: oldestAge,
      newestPacketAge: newestAge,
      queueSizeBytes: totalBytes,
      storageUsagePercent: (totalBytes / (10 * 1024 * 1024) * 100).clamp(0.0, 100.0),
      estimatedRemainingCapacityMB: 50.0 - (totalBytes / (1024 * 1024)),
      batteryPolicy: batteryPolicy,
      storagePolicy: storagePolicy,
      isCorruptionDetected: false,
      lastRecoveryAt: now,
    );
  }
}
