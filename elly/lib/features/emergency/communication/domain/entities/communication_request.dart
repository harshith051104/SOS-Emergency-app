/// communication_request.dart
///
/// Dispatch request DTO containing recipient, priority, message payload, and retry requirements.

library;

import 'dart:convert';
import 'package:flutter/foundation.dart';

enum MessagePriority {
  critical, // SOS Activated, Heartbeat Lost, Escalation
  high,     // Location Update, Health Update
  normal,   // Informational
}

@immutable
class CommunicationRequest {
  CommunicationRequest({
    String? requestId,
    String? recipient,
    dynamic priority = MessagePriority.high,
    this.messageType = 'SOS_ALERT',
    Map<String, dynamic>? payload,
    this.attachments = const [],
    this.retryCount = 0,
    String? sessionId,
    dynamic payloadJson,
    dynamic guaranteeLevel,
    List<dynamic>? recipientTargets,
    DateTime? createdAt,
  })  : requestId = requestId ?? 'req_${DateTime.now().millisecondsSinceEpoch}',
        recipient = recipient ?? (recipientTargets?.isNotEmpty == true ? recipientTargets!.first.toString() : 'primary_contact'),
        priority = priority is MessagePriority
            ? priority
            : (priority is String
                ? MessagePriority.values.firstWhere(
                    (p) => p.name.toLowerCase() == priority.toString().toLowerCase(),
                    orElse: () => MessagePriority.high,
                  )
                : MessagePriority.high),
        payload = payload ??
            (payloadJson is Map<String, dynamic>
                ? payloadJson
                : (payloadJson is String
                    ? (payloadJson.startsWith('{')
                        ? Map<String, dynamic>.from(jsonDecode(payloadJson) as Map)
                        : {'data': payloadJson})
                    : const {})),
        sessionId = sessionId ?? 'session_default',
        createdAt = createdAt ?? DateTime.now();

  final String requestId;
  final String recipient;
  final MessagePriority priority;
  final String messageType;
  final Map<String, dynamic> payload;
  final List<String> attachments;
  final int retryCount;

  // Backwards compatibility fields for existing telemetry console & tests
  final String sessionId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'recipient': recipient,
        'priority': priority.name,
        'messageType': messageType,
        'payload': payload,
        'attachments': attachments,
        'retryCount': retryCount,
        'sessionId': sessionId,
        'createdAt': createdAt.toIso8601String(),
      };
}
