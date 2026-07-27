/// sos_countdown_state.dart
///
/// State machine & event model for the SOS Countdown Engine.

library;

enum SosCountdownStatus { idle, running, cancelled, completed }

/// Immutable state model representing the current countdown status.
class SosCountdownStateModel {
  const SosCountdownStateModel({
    this.status = SosCountdownStatus.idle,
    this.secondsRemaining = 10,
    this.totalDurationSeconds = 10,
    this.triggerSource = 'MANUAL SOS',
  });

  final SosCountdownStatus status;
  final int secondsRemaining;
  final int totalDurationSeconds;
  final String triggerSource;

  double get progressFraction =>
      totalDurationSeconds > 0 ? (secondsRemaining / totalDurationSeconds).clamp(0.0, 1.0) : 0.0;

  SosCountdownStateModel copyWith({
    SosCountdownStatus? status,
    int? secondsRemaining,
    int? totalDurationSeconds,
    String? triggerSource,
  }) {
    return SosCountdownStateModel(
      status: status ?? this.status,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      triggerSource: triggerSource ?? this.triggerSource,
    );
  }
}

/// Event hierarchy emitted by the Countdown Engine.
sealed class SosCountdownEvent {
  const SosCountdownEvent();
}

class CountdownStartedEvent extends SosCountdownEvent {
  const CountdownStartedEvent({required this.triggerSource, required this.durationSeconds});
  final String triggerSource;
  final int durationSeconds;
}

class CountdownTickEvent extends SosCountdownEvent {
  const CountdownTickEvent({required this.secondsRemaining});
  final int secondsRemaining;
}

class CountdownCancelledEvent extends SosCountdownEvent {
  const CountdownCancelledEvent();
}

class CountdownCompletedEvent extends SosCountdownEvent {
  const CountdownCompletedEvent({required this.triggerSource});
  final String triggerSource;
}
