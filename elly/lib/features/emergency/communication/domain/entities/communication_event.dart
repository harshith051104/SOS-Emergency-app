/// communication_event.dart
///
/// Event hierarchy representing real-time milestones during the execution
/// of the Emergency Communication Engine.

library;

import 'package:flutter/foundation.dart';
import 'emergency_dispatch_request.dart';
import 'dispatch_result.dart';

@immutable
sealed class CommunicationEvent {
  const CommunicationEvent();
}

class DispatchPreparingEvent extends CommunicationEvent {
  const DispatchPreparingEvent({required this.request, required this.stepName});
  final EmergencyDispatchRequest request;
  final String stepName;
}

class DialerLaunchingEvent extends CommunicationEvent {
  const DialerLaunchingEvent({required this.emergencyNumber});
  final String emergencyNumber;
}

class DialerLaunchedEvent extends CommunicationEvent {
  const DialerLaunchedEvent({required this.emergencyNumber});
  final String emergencyNumber;
}

class DispatchCompletedEvent extends CommunicationEvent {
  const DispatchCompletedEvent({required this.result});
  final DispatchResult result;
}

class DispatchFailedEvent extends CommunicationEvent {
  const DispatchFailedEvent({required this.reason, required this.emergencyNumber});
  final String reason;
  final String emergencyNumber;
}

class EmergencySessionStartedEvent extends CommunicationEvent {
  const EmergencySessionStartedEvent({required this.sessionId});
  final String sessionId;
}

class TransportSelectedEvent extends CommunicationEvent {
  const TransportSelectedEvent({
    required this.requestId,
    required this.selectedTransport,
    required this.score,
    this.transportId = '',
    this.messageId = '',
  });
  final String requestId;
  final String selectedTransport;
  final double score;
  final String transportId;
  final String messageId;
}

class MessageSendingEvent extends CommunicationEvent {
  const MessageSendingEvent({
    required this.requestId,
    required this.transport,
    this.messageId = '',
    this.transportId = '',
  });
  final String requestId;
  final String transport;
  final String messageId;
  final String transportId;
}

class MessageDeliveredEvent extends CommunicationEvent {
  MessageDeliveredEvent(this.status, {
    this.messageId = '',
    this.transportId = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();


  final dynamic status;
  final String messageId;
  final String transportId;
  final DateTime timestamp;
}

class EscalationStartedEvent extends CommunicationEvent {
  const EscalationStartedEvent({
    required this.requestId,
    this.fromTransport = '',
    this.toTransport = '',
    this.messageId = '',
    this.stageIndex = 0,
  });
  final String requestId;
  final String fromTransport;
  final String toTransport;
  final String messageId;
  final int stageIndex;
}

class EscalationCompletedEvent extends CommunicationEvent {
  const EscalationCompletedEvent({
    required this.requestId,
    this.finalTransport = '',
    this.successfulTransport = '',
    this.messageId = '',
  });
  final String requestId;
  final String finalTransport;
  final String successfulTransport;
  final String messageId;
}


class TransportFailedEvent extends CommunicationEvent {
  const TransportFailedEvent({
    required this.requestId,
    required this.transport,
    required this.reason,
    this.transportId = '',
    this.messageId = '',
  });
  final String requestId;
  final String transport;
  final String reason;
  final String transportId;
  final String messageId;
}
