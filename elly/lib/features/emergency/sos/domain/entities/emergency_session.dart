/// emergency_session.dart
///
/// Domain entity representing a live or completed emergency session.
/// Keeps track of real-time responder responses, location, battery,
/// and elapsed session metrics.

library;

import 'package:equatable/equatable.dart';
import '../../../responders/domain/entities/responder.dart';

/// The status of a responder in the current active session.
enum ResponderSessionState {
  /// Responder is in queue but has not yet been notified.
  pending,

  /// Responder has been sent a notification and the system is awaiting ACK.
  notified,

  /// Responder has acknowledged the emergency alert.
  accepted,

  /// Responder was notified but failed to acknowledge within the timeout window.
  timedOut,
}

/// Real-time status tracker for a specific responder during an emergency session.
class ResponderSessionStatus extends Equatable {
  const ResponderSessionStatus({
    required this.responder,
    required this.state,
    this.updatedAt,
  });

  final Responder responder;
  final ResponderSessionState state;
  final DateTime? updatedAt;

  ResponderSessionStatus copyWith({
    ResponderSessionState? state,
    DateTime? updatedAt,
  }) {
    return ResponderSessionStatus(
      responder: responder,
      state: state ?? this.state,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [responder, state, updatedAt];
}

/// The compiled details of the active emergency session.
class EmergencySession extends Equatable {
  const EmergencySession({
    required this.sessionId,
    required this.startedAt,
    this.endedAt,
    required this.batteryLevel,
    required this.currentAddress,
    required this.locationAccuracy,
    required this.medicalProfileSummary,
    required this.responderStatuses,
  });

  /// Unique session reference, e.g. #EL-2026-000001
  final String sessionId;

  /// Time the SOS confirmation ended and packet was generated.
  final DateTime startedAt;

  /// Time the user ended the emergency.
  final DateTime? endedAt;

  /// Device battery level (e.g. 82%) included in the packet.
  final String batteryLevel;

  /// Shared address
  final String currentAddress;

  /// Accuracy radius (e.g. 5m)
  final String locationAccuracy;

  /// Summarised medical info shared with responders
  final String medicalProfileSummary;

  /// Status of each responder in this session
  final List<ResponderSessionStatus> responderStatuses;

  /// Calculates elapsed duration of the session.
  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  EmergencySession copyWith({
    DateTime? endedAt,
    String? batteryLevel,
    String? currentAddress,
    String? locationAccuracy,
    List<ResponderSessionStatus>? responderStatuses,
  }) {
    return EmergencySession(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      currentAddress: currentAddress ?? this.currentAddress,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
      medicalProfileSummary: medicalProfileSummary,
      responderStatuses: responderStatuses ?? this.responderStatuses,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        startedAt,
        endedAt,
        batteryLevel,
        currentAddress,
        locationAccuracy,
        medicalProfileSummary,
        responderStatuses,
      ];
}
