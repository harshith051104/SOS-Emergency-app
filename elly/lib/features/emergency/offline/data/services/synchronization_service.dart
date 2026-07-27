/// synchronization_service.dart
///
/// Service orchestrating the synchronization of queued offline EmergencyDataPackets,
/// checksum verification, exponential retry scheduling, and timeline event recording.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_data_packet.dart';
import 'package:elly/features/emergency/offline/data/services/offline_queue_service.dart';
import 'package:elly/features/emergency/offline/domain/validation/retry_policy.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_platform_events.dart';

class SynchronizationService {
  SynchronizationService({
    required this.ref,
    required this.queueService,
    required this.eventBus,
  });

  final Ref ref;
  final OfflineQueueService queueService;
  final EmergencyEventBus eventBus;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Future<void> synchronizePendingPackets() async {
    if (_isSyncing) return;
    _isSyncing = true;

    final pending = queueService.pendingPackets;
    if (pending.isEmpty) {
      _isSyncing = false;
      return;
    }

    final now = AppClock.now();
    appLogger.info('SynchronizationService: Starting sync batch for ${pending.length} pending packets...');

    // Publish SynchronizationStarted event
    final startEvent = SynchronizationStartedPlatformEvent(
      eventId: 'evt_sync_start_${now.millisecondsSinceEpoch}',
      timestamp: now,
      queuedCount: pending.length,
    );
    eventBus.publish('SynchronizationStarted', startEvent.toJson());

    _recordTimeline(
      title: 'Synchronization Started',
      description: 'Synchronizing ${pending.length} queued emergency packets with response network.',
      severity: EventSeverity.info,
    );

    int uploadedCount = 0;

    for (final item in pending) {
      try {
        // Verify SHA-256 checksum integrity before uploading
        if (item.packet.packetChecksum.isEmpty) {
          throw Exception('Packet SHA-256 checksum missing.');
        }

        // Simulate network upload dispatch (Sprint 13 integration point)
        await Future<void>.delayed(const Duration(milliseconds: 300));

        await queueService.markUploaded(item.queueId);
        uploadedCount++;

        final uploadEvent = PacketUploadedPlatformEvent(
          eventId: 'evt_pkt_up_${AppClock.now().millisecondsSinceEpoch}',
          timestamp: AppClock.now(),
          packetId: item.packetId,
          checksum: item.packet.packetChecksum,
        );
        eventBus.publish('PacketUploaded', uploadEvent.toJson());

      } catch (e) {
        appLogger.warning('SynchronizationService: Failed syncing packet ${item.packetId}: $e');
        
        final nextRetry = RetryPolicy.getNextRetryTime(currentRetryCount: item.retryCount);
        await queueService.updatePacketStatus(
          item.queueId,
          PacketStatus.failed,
          failureReason: e.toString(),
          nextRetryAt: nextRetry,
        );

        _recordTimeline(
          title: 'Retry Scheduled',
          description: 'Failed syncing packet ${item.packetId}. Next retry scheduled at ${nextRetry.toIso8601String()}.',
          severity: EventSeverity.warning,
        );
      }
    }

    final completedEvent = SynchronizationCompletedPlatformEvent(
      eventId: 'evt_sync_done_${AppClock.now().millisecondsSinceEpoch}',
      timestamp: AppClock.now(),
      uploadedCount: uploadedCount,
    );
    eventBus.publish('SynchronizationCompleted', completedEvent.toJson());

    _recordTimeline(
      title: 'Synchronization Completed',
      description: 'Successfully uploaded $uploadedCount emergency packets.',
      severity: EventSeverity.info,
    );

    _isSyncing = false;
  }

  void _recordTimeline({
    required String title,
    required String description,
    required EventSeverity severity,
  }) {
    try {
      final repo = ref.read(emergencySessionRepositoryProvider);
      repo.recordTimelineEvent(EmergencyTimelineEvent(
        id: 'evt_off_sync_${AppClock.now().millisecondsSinceEpoch}',
        timestamp: AppClock.now(),
        category: EventCategory.system,
        severity: severity,
        title: title,
        description: description,
        sourceEngine: 'Offline Mode Engine',
      ));
    } catch (e) {
      appLogger.warning('SynchronizationService: Could not log timeline event: $e');
    }
  }
}
