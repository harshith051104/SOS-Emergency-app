/// response_engine_update.dart
///
/// A single event emitted by [EmergencyResponseEngine.execute]'s stream.
/// The UI assembles these into a live timeline.

library;

import 'package:equatable/equatable.dart';

import '../enums/notification_method.dart';
import '../enums/response_update_type.dart';
import 'responder.dart';

/// Immutable event describing a step in the emergency response execution.
class ResponseEngineUpdate extends Equatable {
  const ResponseEngineUpdate({
    required this.type,
    required this.timestamp,
    this.responder,
    this.method,
    this.message,
    this.success,
  });

  // ── Convenience constructors ───────────────────────────────────────────────

  factory ResponseEngineUpdate.started() => ResponseEngineUpdate(
        type: ResponseUpdateType.started,
        timestamp: DateTime.now(),
        message: 'Emergency Response Engine started.',
      );

  factory ResponseEngineUpdate.generatingSummary(String summary) =>
      ResponseEngineUpdate(
        type: ResponseUpdateType.generatingSummary,
        timestamp: DateTime.now(),
        message: summary,
      );

  factory ResponseEngineUpdate.notifying(
    Responder responder,
    NotificationMethod method,
  ) =>
      ResponseEngineUpdate(
        type: ResponseUpdateType.notifying,
        timestamp: DateTime.now(),
        responder: responder,
        method: method,
        message: 'Contacting ${responder.name} via ${method.displayName}…',
      );

  factory ResponseEngineUpdate.notified(
    Responder responder,
    NotificationMethod method, {
    required bool success,
  }) =>
      ResponseEngineUpdate(
        type: ResponseUpdateType.notified,
        timestamp: DateTime.now(),
        responder: responder,
        method: method,
        success: success,
        message: success
            ? '${method.displayName} sent to ${responder.name}.'
            : '${method.displayName} to ${responder.name} failed.',
      );

  factory ResponseEngineUpdate.acknowledged(Responder responder) =>
      ResponseEngineUpdate(
        type: ResponseUpdateType.acknowledged,
        timestamp: DateTime.now(),
        responder: responder,
        success: true,
        message: '${responder.name} acknowledged the emergency.',
      );

  factory ResponseEngineUpdate.timedOut(Responder responder) =>
      ResponseEngineUpdate(
        type: ResponseUpdateType.timedOut,
        timestamp: DateTime.now(),
        responder: responder,
        success: false,
        message: 'No response from ${responder.name}.',
      );

  factory ResponseEngineUpdate.escalating(
    Responder from,
    Responder? to,
  ) =>
      ResponseEngineUpdate(
        type: ResponseUpdateType.escalating,
        timestamp: DateTime.now(),
        responder: from,
        message: to != null
            ? 'Escalating to ${to.name}…'
            : 'All responders contacted.',
      );

  factory ResponseEngineUpdate.completed({bool acknowledged = false}) =>
      ResponseEngineUpdate(
        type: ResponseUpdateType.completed,
        timestamp: DateTime.now(),
        success: acknowledged,
        message: acknowledged
            ? 'Emergency acknowledged. Help is on the way.'
            : 'All responders notified. Awaiting assistance.',
      );

  factory ResponseEngineUpdate.failed(String reason) => ResponseEngineUpdate(
        type: ResponseUpdateType.failed,
        timestamp: DateTime.now(),
        success: false,
        message: reason,
      );

  factory ResponseEngineUpdate.cancelled() => ResponseEngineUpdate(
        type: ResponseUpdateType.cancelled,
        timestamp: DateTime.now(),
        message: 'Emergency response cancelled.',
      );

  // ── Fields ─────────────────────────────────────────────────────────────────

  /// What kind of event this is.
  final ResponseUpdateType type;

  /// When this event occurred.
  final DateTime timestamp;

  /// The responder this event relates to (null for engine-level events).
  final Responder? responder;

  /// The notification channel used (null for non-notification events).
  final NotificationMethod? method;

  /// Human-readable description displayed in the timeline.
  final String? message;

  /// True = action succeeded; false = failed; null = in-progress / N/A.
  final bool? success;

  @override
  List<Object?> get props =>
      [type, timestamp, responder, method, message, success];
}
