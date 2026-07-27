/// reliability_state_machine.dart
///
/// Deterministic state machine governing reliability states and logging transitions.

library;

import 'dart:async';
import '../../domain/entities/reliability_state.dart';
import '../../domain/entities/reliability_event.dart';
import 'reliability_event_bus.dart';

class ReliabilityStateMachine {
  ReliabilityStateMachine({
    ReliabilityEventBus? eventBus,
  })  : _eventBus = eventBus ?? ReliabilityEventBus(),
        _stateController = StreamController<ReliabilityState>.broadcast();

  final ReliabilityEventBus _eventBus;
  final StreamController<ReliabilityState> _stateController;

  ReliabilityState _currentState = const ReliabilityState(status: ReliabilityStatus.idle);

  Stream<ReliabilityState> get stateStream => _stateController.stream;
  ReliabilityState get currentState => _currentState;

  void transitionTo(ReliabilityStatus newStatus, {String? sessionId, String? error}) {
    if (_currentState.status == newStatus) return;

    _currentState = ReliabilityState(
      status: newStatus,
      sessionId: sessionId ?? _currentState.sessionId,
      startedAt: _currentState.startedAt ?? DateTime.now(),
      lastTransitionTime: DateTime.now(),
      lastError: error,
    );

    if (!_stateController.isClosed) {
      Future<void>(() {
        if (!_stateController.isClosed) _stateController.add(_currentState);
      });
    }
    Future<void>(() => _eventBus.publish(ReliabilityStateChangedEvent(_currentState)));
  }

  Future<void> dispose() async {
    await _stateController.close();
  }
}
