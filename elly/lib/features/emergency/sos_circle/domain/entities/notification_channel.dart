/// notification_channel.dart
///
/// Interface & Channel Result model supporting future transport extensions
/// (SMS, WhatsApp, Push, Backend API, Email) without modifying core orchestration.

library;

import 'package:flutter/foundation.dart';
import 'sos_notification_request.dart';
import 'emergency_contact.dart';

enum NotificationDeliveryStatus {
  pending,
  queued,
  sending,
  delivered,
  acknowledged,
  failed,
  expired,
}

@immutable
class ChannelResult {
  const ChannelResult({
    required this.channelId,
    required this.status,
    required this.timestamp,
    this.messageId,
    this.failureReason,
  });

  final String channelId;
  final NotificationDeliveryStatus status;
  final DateTime timestamp;
  final String? messageId;
  final String? failureReason;
}

abstract class NotificationChannel {
  String get channelId;
  String get channelName;

  Future<ChannelResult> send(
    SOSNotificationRequest request,
    EmergencyContact contact,
  );
}
