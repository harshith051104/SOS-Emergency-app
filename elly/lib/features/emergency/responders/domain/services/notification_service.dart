/// notification_service.dart
///
/// Abstract contract for dispatching a single notification to a responder.
///
/// Phase 1: [MockNotificationService] simulates delivery.
/// Phase 2+: Add real implementations:
///   - TwilioSmsService
///   - FirebasePushService
///   - SendGridEmailService
///   - VoiceCallService

library;

import '../entities/responder.dart';
import '../enums/notification_method.dart';

/// Result of a single notification dispatch attempt.
class NotificationResult {
  const NotificationResult({
    required this.responderId,
    required this.method,
    required this.success,
    this.errorMessage,
    this.sentAt,
  });

  final String responderId;
  final NotificationMethod method;
  final bool success;
  final String? errorMessage;
  final DateTime? sentAt;
}

/// Contract for sending a notification to a single responder via one channel.
abstract class NotificationService {
  /// Dispatches a message to [responder] via [method].
  ///
  /// Implementations must NOT throw — they should return a
  /// [NotificationResult] with [success] = false and an [errorMessage].
  ///
  /// [message] is the emergency summary text to include in the notification.
  Future<NotificationResult> send({
    required Responder responder,
    required NotificationMethod method,
    required String message,
  });
}
