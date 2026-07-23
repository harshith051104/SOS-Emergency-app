/// emergency_event.dart
///
/// The core domain entity representing a single emergency event.
/// Every activation — regardless of trigger type — produces an [EmergencyEvent].
///
/// UUID-keyed so that:
///   - Each event is uniquely identifiable for audit logs
///   - The backend (Phase 2+) can store/query events by ID
///   - UI can track the "active event" without ambiguity

library;

import 'package:equatable/equatable.dart';

import '../enums/emergency_status.dart';
import '../enums/emergency_type.dart';

/// Immutable representation of a single emergency occurrence.
class EmergencyEvent extends Equatable {
  const EmergencyEvent({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.activatedAt,
    this.cancelledAt,
    this.completedAt,
    this.failureReason,
  });

  /// UUID v4 — unique identifier for this emergency event.
  final String id;

  /// How this emergency was triggered (manual, voice, etc.).
  final EmergencyType type;

  /// Current lifecycle status of this event.
  final EmergencyStatus status;

  /// When the event was first created (user tapped SOS / trigger fired).
  final DateTime createdAt;

  /// When the emergency became fully active (post-countdown + backend ACK).
  final DateTime? activatedAt;

  /// When the user cancelled (before or during countdown).
  final DateTime? cancelledAt;

  /// When the emergency was resolved / completed.
  final DateTime? completedAt;

  /// Human-readable reason if [status] is [EmergencyStatus.failed].
  final String? failureReason;

  /// Returns a copy of this event with the given fields overridden.
  EmergencyEvent copyWith({
    String? id,
    EmergencyType? type,
    EmergencyStatus? status,
    DateTime? createdAt,
    DateTime? activatedAt,
    DateTime? cancelledAt,
    DateTime? completedAt,
    String? failureReason,
  }) {
    return EmergencyEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      activatedAt: activatedAt ?? this.activatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        status,
        createdAt,
        activatedAt,
        cancelledAt,
        completedAt,
        failureReason,
      ];
}
