/// emergency_response_plan.dart
///
/// An assembled plan that the [EmergencyResponseEngine] executes.
/// Contains the ordered list of responders and the generated emergency summary.

library;

import 'package:equatable/equatable.dart';

import 'responder.dart';

/// The compiled response plan passed to [EmergencyResponseEngine.execute].
class EmergencyResponsePlan extends Equatable {
  const EmergencyResponsePlan({
    required this.responders,
    this.emergencySummary,
    this.escalationDelaySeconds = 30,
  });

  /// Enabled responders sorted by [Responder.priority] ascending.
  /// The engine notifies them in this order, escalating if no acknowledgement.
  final List<Responder> responders;

  /// Human-readable emergency summary sent with each notification.
  /// Generated from the [EmergencyEvent] by the engine before dispatching.
  final String? emergencySummary;

  /// Seconds to wait for acknowledgement from each responder before
  /// escalating to the next. Used by production engines; mocks run faster.
  final int escalationDelaySeconds;

  EmergencyResponsePlan copyWith({
    List<Responder>? responders,
    String? emergencySummary,
    int? escalationDelaySeconds,
  }) {
    return EmergencyResponsePlan(
      responders: responders ?? this.responders,
      emergencySummary: emergencySummary ?? this.emergencySummary,
      escalationDelaySeconds:
          escalationDelaySeconds ?? this.escalationDelaySeconds,
    );
  }

  @override
  List<Object?> get props =>
      [responders, emergencySummary, escalationDelaySeconds];
}
