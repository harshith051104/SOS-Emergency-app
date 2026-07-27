/// sos_notification_service.dart
///
/// Orchestrates event-driven simulation for SOS Circle emergency notifications
/// using extensible NotificationChannel instances following Open/Closed Principle.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/sos_notification_request.dart';
import '../../domain/entities/sos_notification_result.dart';
import '../../domain/entities/sos_circle_event.dart';
import '../../domain/entities/notification_channel.dart';
import '../../domain/entities/emergency_contact.dart';

class SimulatedNotificationChannel implements NotificationChannel {
  @override
  String get channelId => 'chn_simulated';

  @override
  String get channelName => 'Simulated Notification Gateway';

  @override
  Future<ChannelResult> send(SOSNotificationRequest request, EmergencyContact contact) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ChannelResult(
      channelId: channelId,
      status: NotificationDeliveryStatus.delivered,
      timestamp: DateTime.now(),
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}_${contact.id}',
    );
  }
}

class SOSNotificationService {
  SOSNotificationService({List<NotificationChannel>? channels})
      : _channels = channels ?? [SimulatedNotificationChannel()],
        _eventController = StreamController<SOSCircleEvent>.broadcast();

  final List<NotificationChannel> _channels;
  final StreamController<SOSCircleEvent> _eventController;

  Stream<SOSCircleEvent> get eventStream => _eventController.stream;
  List<NotificationChannel> get channels => List.unmodifiable(_channels);

  /// Executes notification dispatch for enabled contacts in priority order across channels.
  Future<SOSNotificationResult> dispatchNotifications(SOSNotificationRequest request) async {
    final startedAt = DateTime.now();
    appLogger.info('SOSNotificationService: Starting notification dispatch for Session ${request.sessionId}');

    final enabledContacts = request.contacts.where((c) => c.isEnabled).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    _emit(SOSNotificationStartedEvent(request: request, totalContacts: enabledContacts.length));

    final notified = <String>[];
    final failed = <String>[];
    final failures = <String, String>{};

    for (final contact in enabledContacts) {
      try {
        _emit(ContactProcessingEvent(
          contactId: contact.id,
          contactName: contact.fullName,
          step: 'Preparing Payload (${contact.relationship})',
        ));

        _emit(ContactQueuedEvent(
          contactId: contact.id,
          contactName: contact.fullName,
        ));

        for (final channel in _channels) {
          final result = await channel.send(request, contact);
          if (result.status == NotificationDeliveryStatus.delivered ||
              result.status == NotificationDeliveryStatus.acknowledged) {
            _emit(ContactCompletedEvent(
              contactId: contact.id,
              contactName: contact.fullName,
              channel: channel.channelName,
            ));
            notified.add(contact.id);
            appLogger.info('SOSNotificationService: Contact ${contact.fullName} notified via ${channel.channelName}');
          } else {
            throw Exception(result.failureReason ?? 'Delivery failed');
          }
        }
      } catch (e) {
        failed.add(contact.id);
        failures[contact.id] = e.toString();
        _emit(SOSNotificationFailedEvent(
          contactId: contact.id,
          contactName: contact.fullName,
          reason: e.toString(),
        ));
        appLogger.error('SOSNotificationService: Failed notifying ${contact.fullName}: $e');
      }
    }

    final completedAt = DateTime.now();
    final result = SOSNotificationResult(
      success: failed.isEmpty && notified.isNotEmpty,
      notifiedContacts: List.unmodifiable(notified),
      failedContacts: List.unmodifiable(failed),
      startedAt: startedAt,
      completedAt: completedAt,
      failures: Map.unmodifiable(failures),
    );

    _emit(SOSNotificationCompletedEvent(result: result));
    appLogger.info('SOSNotificationService: Dispatch completed. Notified ${notified.length}/${enabledContacts.length}');
    return result;
  }

  void _emit(SOSCircleEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void dispose() {
    _eventController.close();
  }
}
