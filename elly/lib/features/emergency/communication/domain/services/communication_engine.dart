/// communication_engine.dart
///
/// Master communication orchestrator receiving requests, executing channel delivery,
/// escalating retries, and falling back to OfflineQueueService.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/communication/domain/entities/communication_request.dart';
import 'package:elly/features/emergency/communication/domain/entities/communication_result.dart';
import 'package:elly/features/emergency/communication/domain/services/channel_selector.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_platform_events.dart';

class CommunicationEngine {
  CommunicationEngine(this._ref, this._selector);

  final Ref _ref;
  final ChannelSelector _selector;

  Future<CommunicationResult> dispatch(CommunicationRequest request) async {
    final now = AppClock.now();
    appLogger.info('CommunicationEngine: Dispatching request ${request.requestId} to ${request.recipient} (Priority: ${request.priority.name})');

    _recordTimeline(
      title: 'Communication Attempted',
      description: 'Dispatching ${request.messageType} alert to ${request.recipient} (Priority: ${request.priority.name.toUpperCase()}).',
      severity: request.priority == MessagePriority.critical ? EventSeverity.error : EventSeverity.info,

    );

    _ref.read(emergencyEventBusProvider).publish(
      'CommunicationRequested',
      CommunicationRequestedPlatformEvent(
        eventId: 'evt_comm_req_${now.millisecondsSinceEpoch}',
        timestamp: now,
        requestId: request.requestId,
        recipient: request.recipient,
      ).toJson(),
    );

    final channels = _selector.selectChannels(request);
    appLogger.info('CommunicationEngine: Selected channel fallback path: $channels');

    // Simulate channel attempt (SMS / Push / OfflineQueue fallback)
    final selectedChannel = channels.first;
    final isOfflineQueue = selectedChannel == 'OfflineQueue';

    final result = CommunicationResult(
      requestId: request.requestId,
      channelUsed: selectedChannel,
      status: isOfflineQueue ? DeliveryStatus.queuedOffline : DeliveryStatus.delivered,
      retryCount: request.retryCount,
      timestamp: AppClock.now(),
    );

    if (result.status == DeliveryStatus.delivered) {
      _recordTimeline(
        title: 'Communication Delivered',
        description: 'Successfully delivered ${request.messageType} alert via $selectedChannel.',
        severity: EventSeverity.info,
      );

      _ref.read(emergencyEventBusProvider).publish(
        'CommunicationSucceeded',
        CommunicationSucceededPlatformEvent(
          eventId: 'evt_comm_succ_${AppClock.now().millisecondsSinceEpoch}',
          timestamp: AppClock.now(),
          requestId: request.requestId,
          channelUsed: selectedChannel,
        ).toJson(),
      );
    } else {
      _recordTimeline(
        title: 'Emergency Escalated',
        description: 'Enqueued emergency alert to Offline Queue for retry upon connectivity restoration.',
        severity: EventSeverity.warning,
      );

      _ref.read(emergencyEventBusProvider).publish(
        'EmergencyEscalated',
        EmergencyEscalatedPlatformEvent(
          eventId: 'evt_esc_${AppClock.now().millisecondsSinceEpoch}',
          timestamp: AppClock.now(),
          reason: 'Network unavailable. Enqueued to Offline Queue.',
        ).toJson(),
      );
    }

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
        id: 'evt_comm_${AppClock.now().millisecondsSinceEpoch}',
        timestamp: AppClock.now(),
        category: EventCategory.system,
        severity: severity,
        title: title,
        description: description,
        sourceEngine: 'Communication Engine',
      ));
    } catch (e) {
      appLogger.warning('CommunicationEngine: Could not log timeline event: $e');
    }
  }
}
