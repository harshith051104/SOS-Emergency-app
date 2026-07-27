/// offline_resilience_controller.dart
///
/// Master controller managing app restart session restoration, queue recovery,
/// scheduler resumption, and offline health report updates.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/packet/domain/services/emergency_packet_scheduler.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';
import 'package:elly/features/emergency/session/domain/entities/session_state.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/offline_resilience/domain/entities/offline_health_report.dart';
import 'package:elly/features/emergency/offline_resilience/domain/services/queue_recovery_service.dart';
import 'package:elly/features/emergency/offline_resilience/domain/services/storage_manager.dart';
import 'package:elly/features/emergency/offline_resilience/domain/services/offline_health_monitor.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_platform_events.dart';

class OfflineResilienceController extends StateNotifier<OfflineHealthReport?> {
  OfflineResilienceController(
    this._ref,
    this._recoveryService,
    this._storageManager,
    this._healthMonitor,
  ) : super(null) {
    _initializeResilienceEngine();
  }

  final Ref _ref;
  final QueueRecoveryService _recoveryService;
  final StorageManager _storageManager;
  final OfflineHealthMonitor _healthMonitor;

  Future<void> _initializeResilienceEngine() async {
    appLogger.info('OfflineResilienceController: Initializing Offline Resilience & Survivability Engine...');

    // 1. Startup Queue Integrity Recovery & Low Storage Archiving
    final recoveryResult = await _recoveryService.verifyAndRecoverQueue();
    await _storageManager.archiveUploadedPackets();
    state = _healthMonitor.generateReport();


    // 2. Interrupted Session & Scheduler Auto-Restoration
    final sessionSnapshot = _ref.read(sessionSnapshotProvider);
    final sessionState = sessionSnapshot.session.state;

    if (sessionState == SessionState.active || sessionState == SessionState.starting || sessionState == SessionState.recovering) {
      appLogger.info('OfflineResilienceController: Interrupted emergency session detected (${sessionSnapshot.session.sessionId}). Restoring session & scheduler...');

      _recordTimeline(
        title: 'Application Recovery',
        description: 'Restored interrupted active emergency session [Session ID: ${sessionSnapshot.session.sessionId}].',
        severity: EventSeverity.warning,
      );

      // Resume Continuous Packet Scheduler
      _ref.read(emergencyPacketSchedulerProvider.notifier).startScheduler();

      // Trigger Synchronization if online
      final netState = _ref.read(networkStateProvider);
      if (netState.name == 'online') {
        _ref.read(synchronizationServiceProvider).synchronizePendingPackets();
      }
    }

    _ref.read(emergencyEventBusProvider).publish(
      'OfflineRecoveryCompleted',
      OfflineRecoveryCompletedPlatformEvent(
        eventId: 'evt_off_rec_comp_${AppClock.now().millisecondsSinceEpoch}',
        timestamp: AppClock.now(),
        recoveredCount: recoveryResult.recoveredPackets,
      ).toJson(),
    );
  }

  void refreshReport() {
    state = _healthMonitor.generateReport();
  }

  void _recordTimeline({
    required String title,
    required String description,
    required EventSeverity severity,
  }) {
    try {
      final repo = _ref.read(emergencySessionRepositoryProvider);
      repo.recordTimelineEvent(EmergencyTimelineEvent(
        id: 'evt_resil_${AppClock.now().millisecondsSinceEpoch}',
        timestamp: AppClock.now(),
        category: EventCategory.system,
        severity: severity,
        title: title,
        description: description,
        sourceEngine: 'Resilience Engine',
      ));
    } catch (e) {
      appLogger.warning('OfflineResilienceController: Could not log timeline event: $e');
    }
  }
}
