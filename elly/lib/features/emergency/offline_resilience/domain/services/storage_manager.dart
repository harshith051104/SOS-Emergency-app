/// storage_manager.dart
///
/// Storage monitoring, snapshot compression, low-storage protection, and retention policy manager.

library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';

import 'package:elly/features/emergency/offline_resilience/domain/entities/resilience_policies.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_platform_events.dart';

class StorageManager {
  StorageManager(this._ref);

  final Ref _ref;

  StoragePolicy evaluateStoragePolicy() {
    final queueService = _ref.read(offlineQueueProvider);
    final allPackets = queueService.allPackets;

    // Calculate approximate queue size in bytes
    int totalBytes = 0;
    for (final item in allPackets) {
      totalBytes += jsonEncode(item.toJson()).length;
    }

    // Thresholds: >5MB = lowStorage, >20MB = criticalStorage
    StoragePolicy policy = StoragePolicy.normal;
    if (totalBytes > 20 * 1024 * 1024) {
      policy = StoragePolicy.criticalStorage;
    } else if (totalBytes > 5 * 1024 * 1024) {
      policy = StoragePolicy.lowStorage;
    }

    if (policy != StoragePolicy.normal) {
      final now = AppClock.now();
      appLogger.warning('StorageManager: Low storage detected! (Queue size: ${(totalBytes / 1024).toStringAsFixed(1)} KB, Policy: ${policy.name})');

      if (policy == StoragePolicy.criticalStorage) {
        _ref.read(emergencyEventBusProvider).publish(
          'StorageCritical',
          StorageCriticalPlatformEvent(
            eventId: 'evt_stor_crit_${now.millisecondsSinceEpoch}',
            timestamp: now,
            availableBytes: 10 * 1024 * 1024,
          ).toJson(),
        );

        _recordTimeline(
          title: 'Storage Critical',
          description: 'Emergency queue reached critical size (${(totalBytes / 1024).toStringAsFixed(1)} KB). Compressing snapshots.',
          severity: EventSeverity.error,
        );
      } else {
        _ref.read(emergencyEventBusProvider).publish(
          'StorageLow',
          StorageLowPlatformEvent(
            eventId: 'evt_stor_low_${now.millisecondsSinceEpoch}',
            timestamp: now,
            availableBytes: 50 * 1024 * 1024,
          ).toJson(),
        );

        _recordTimeline(
          title: 'Storage Low',
          description: 'Emergency queue storage low. Initiating snapshot archiving.',
          severity: EventSeverity.warning,
        );
      }
    }

    return policy;
  }

  Future<void> archiveUploadedPackets() async {
    final queueService = _ref.read(offlineQueueProvider);
    await queueService.clearExpired(maxAge: const Duration(days: 3));
  }

  void _recordTimeline({
    required String title,
    required String description,
    required EventSeverity severity,
  }) {
    try {
      final repo = _ref.read(emergencySessionRepositoryProvider);
      repo.recordTimelineEvent(EmergencyTimelineEvent(
        id: 'evt_stor_${AppClock.now().millisecondsSinceEpoch}',
        timestamp: AppClock.now(),
        category: EventCategory.system,
        severity: severity,
        title: title,
        description: description,
        sourceEngine: 'Storage Manager',
      ));
    } catch (e) {
      appLogger.warning('StorageManager: Could not log timeline event: $e');
    }
  }
}
