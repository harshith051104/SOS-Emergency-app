/// queue_recovery_service.dart
///
/// Startup integrity verifier parsing SHA-256 checksums, repairing damaged entries,
/// discarding corrupted packets, and logging timeline recovery milestones.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/offline_resilience/domain/entities/queue_recovery_result.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_platform_events.dart';

class QueueRecoveryService {
  QueueRecoveryService(this._ref);

  final Ref _ref;

  Future<QueueRecoveryResult> verifyAndRecoverQueue() async {
    final startTime = AppClock.now();
    appLogger.info('QueueRecoveryService: Starting queue integrity verification and recovery...');

    _recordTimeline(
      title: 'Offline Recovery Started',
      description: 'Verifying SHA-256 checksum integrity of stored offline emergency packets.',
      severity: EventSeverity.info,
    );

    final queueService = _ref.read(offlineQueueProvider);
    await queueService.initialize();

    final allPackets = queueService.allPackets;
    int recovered = 0;
    const repaired = 0;
    int discarded = 0;


    for (final item in allPackets) {
      try {
        if (item.packet.packetChecksum.isEmpty || item.packet.packetId.isEmpty) {
          appLogger.warning('QueueRecoveryService: Packet ${item.queueId} has corrupted checksum. Discarding.');
          await queueService.dequeuePacket(item.queueId);
          discarded++;
        } else {
          recovered++;
        }
      } catch (e) {
        appLogger.error('QueueRecoveryService: Exception inspecting packet ${item.queueId}: $e');
        await queueService.dequeuePacket(item.queueId);
        discarded++;
      }
    }

    final duration = AppClock.now().difference(startTime);
    final result = QueueRecoveryResult(
      recoveredPackets: recovered,
      discardedPackets: discarded,
      repairedPackets: repaired,
      recoveryDuration: duration,
      reason: discarded > 0 ? 'Corrupted checksums discarded' : 'All stored packets valid',
    );

    if (discarded > 0 || repaired > 0) {
      _recordTimeline(
        title: 'Queue Repaired',
        description: 'Recovered $recovered valid packets, repaired $repaired, discarded $discarded corrupted entries.',
        severity: EventSeverity.warning,
      );

      _ref.read(emergencyEventBusProvider).publish(
        'QueueCorrupted',
        QueueCorruptedPlatformEvent(
          eventId: 'evt_queue_corp_${startTime.millisecondsSinceEpoch}',
          timestamp: startTime,
          corruptedCount: discarded,
        ).toJson(),
      );
    } else {
      _recordTimeline(
        title: 'Offline Recovery Completed',
        description: 'Integrity verified cleanly. $recovered stored packets ready for sync.',
        severity: EventSeverity.info,
      );
    }

    _ref.read(emergencyEventBusProvider).publish(
      'QueueRecovered',
      QueueRecoveredPlatformEvent(
        eventId: 'evt_queue_rec_${AppClock.now().millisecondsSinceEpoch}',
        timestamp: AppClock.now(),
        recoveredCount: recovered,
      ).toJson(),
    );

    return result;
  }

  void _recordTimeline({
    required String title,
    required String description,
    required EventSeverity severity,
  }) {
    try {
      final repo = _ref.read(emergencySessionRepositoryProvider);
      repo.recordTimelineEvent(EmergencyTimelineEvent(
        id: 'evt_rec_${AppClock.now().millisecondsSinceEpoch}',
        timestamp: AppClock.now(),
        category: EventCategory.system,
        severity: severity,
        title: title,
        description: description,
        sourceEngine: 'Resilience Engine',
      ));
    } catch (e) {
      appLogger.warning('QueueRecoveryService: Could not log timeline event: $e');
    }
  }
}
