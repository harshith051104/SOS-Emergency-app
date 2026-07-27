/// sos_countdown_engine.dart
///
/// Life-critical SOS Countdown Engine managing 1-Hz countdown timers,
/// event emission, and haptic feedback with strict timer lifecycle safety.

library;

import 'dart:async';
import 'package:flutter/services.dart';
import '../../domain/entities/sos_countdown_state.dart';

class SosCountdownEngine {
  SosCountdownEngine();

  Timer? _timer;
  SosCountdownStateModel _state = const SosCountdownStateModel();
  final _eventController = StreamController<SosCountdownEvent>.broadcast();

  SosCountdownStateModel get state => _state;
  Stream<SosCountdownEvent> get eventStream => _eventController.stream;

  /// Starts the 10-second countdown safely, cancelling any active timers first.
  void startCountdown({String source = 'MANUAL SOS', int durationSeconds = 10}) {
    _stopTimer();

    _state = SosCountdownStateModel(
      status: SosCountdownStatus.running,
      secondsRemaining: durationSeconds,
      totalDurationSeconds: durationSeconds,
      triggerSource: source,
    );

    _eventController.add(
      CountdownStartedEvent(triggerSource: source, durationSeconds: durationSeconds),
    );

    HapticFeedback.heavyImpact();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.status != SosCountdownStatus.running) {
        timer.cancel();
        return;
      }

      final nextSec = (_state.secondsRemaining - 1).clamp(0, 999);

      if (nextSec > 0) {
        _state = _state.copyWith(secondsRemaining: nextSec);
        _eventController.add(CountdownTickEvent(secondsRemaining: nextSec));
        HapticFeedback.lightImpact();
      } else {
        _stopTimer();
        _state = _state.copyWith(secondsRemaining: 0, status: SosCountdownStatus.completed);
        _eventController.add(CountdownCompletedEvent(triggerSource: _state.triggerSource));
        HapticFeedback.vibrate();
      }
    });
  }


  /// Cancels the active countdown immediately and resets to idle.
  void cancelCountdown() {
    if (_state.status == SosCountdownStatus.idle || _state.status == SosCountdownStatus.cancelled) {
      return;
    }

    _stopTimer();
    _state = _state.copyWith(status: SosCountdownStatus.cancelled);
    _eventController.add(const CountdownCancelledEvent());
    HapticFeedback.mediumImpact();
  }

  /// Resets state back to idle.
  void resetToIdle() {
    _stopTimer();
    _state = const SosCountdownStateModel();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _stopTimer();
    _eventController.close();
  }
}
