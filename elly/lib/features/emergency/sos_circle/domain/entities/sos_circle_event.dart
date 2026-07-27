/// sos_circle_event.dart
///
/// Real-time event hierarchy for SOS Circle notifications and updates.

library;

import 'package:flutter/foundation.dart';
import 'sos_notification_request.dart';
import 'sos_notification_result.dart';

@immutable
sealed class SOSCircleEvent {
  const SOSCircleEvent();
}

class SOSNotificationStartedEvent extends SOSCircleEvent {
  const SOSNotificationStartedEvent({
    required this.request,
    required this.totalContacts,
  });

  final SOSNotificationRequest request;
  final int totalContacts;
}

class ContactProcessingEvent extends SOSCircleEvent {
  const ContactProcessingEvent({
    required this.contactId,
    required this.contactName,
    required this.step,
  });

  final String contactId;
  final String contactName;
  final String step;
}

class ContactQueuedEvent extends SOSCircleEvent {
  const ContactQueuedEvent({
    required this.contactId,
    required this.contactName,
  });

  final String contactId;
  final String contactName;
}

class ContactCompletedEvent extends SOSCircleEvent {
  const ContactCompletedEvent({
    required this.contactId,
    required this.contactName,
    required this.channel,
  });

  final String contactId;
  final String contactName;
  final String channel;
}

class SOSNotificationCompletedEvent extends SOSCircleEvent {
  const SOSNotificationCompletedEvent({
    required this.result,
  });

  final SOSNotificationResult result;
}

class SOSNotificationFailedEvent extends SOSCircleEvent {
  const SOSNotificationFailedEvent({
    required this.contactId,
    required this.contactName,
    required this.reason,
  });

  final String contactId;
  final String contactName;
  final String reason;
}
