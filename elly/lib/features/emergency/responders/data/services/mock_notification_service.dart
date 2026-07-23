/// mock_notification_service.dart
///
/// Simulates notification dispatch with realistic delays and a configurable
/// success rate. Never contacts real services.
///
/// Replace with real implementations in Phase 2+:
///   - TwilioSmsService
///   - FirebasePushNotificationService
///   - SendGridEmailService
///   - VoiceCallService

library;

import 'dart:math';

import '../../domain/entities/responder.dart';
import '../../domain/enums/notification_method.dart';
import '../../domain/services/notification_service.dart';

/// Mock notification service — simulates network latency and delivery.
class MockNotificationService implements NotificationService {
  MockNotificationService({
    this.successRate = 0.90,
    this.minDelayMs = 600,
    this.maxDelayMs = 1400,
  });

  /// Probability that a send attempt succeeds (0.0–1.0).
  final double successRate;

  /// Minimum simulated network delay in milliseconds.
  final int minDelayMs;

  /// Maximum simulated network delay in milliseconds.
  final int maxDelayMs;

  final _random = Random();

  @override
  Future<NotificationResult> send({
    required Responder responder,
    required NotificationMethod method,
    required String message,
  }) async {
    // Simulate network latency.
    final delay = minDelayMs + _random.nextInt(maxDelayMs - minDelayMs);
    await Future<void>.delayed(Duration(milliseconds: delay));

    // API method is always marked as not-yet-implemented in Phase 1.
    if (method == NotificationMethod.api) {
      return NotificationResult(
        responderId: responder.id,
        method: method,
        success: false,
        errorMessage: 'API webhook not configured (Phase 2 placeholder).',
        sentAt: DateTime.now(),
      );
    }

    final success = _random.nextDouble() < successRate;
    return NotificationResult(
      responderId: responder.id,
      method: method,
      success: success,
      errorMessage: success
          ? null
          : '[Mock] Delivery failed — simulated error for ${method.displayName}.',
      sentAt: DateTime.now(),
    );
  }
}
