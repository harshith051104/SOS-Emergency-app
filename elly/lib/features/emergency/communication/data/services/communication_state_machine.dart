/// communication_state_machine.dart
///
/// Deterministic state machine governing communication status.

library;

import 'dart:async';
import '../../domain/entities/communication_state.dart';

class CommunicationStateMachine {
  CommunicationStateMachine()
      : _stateController = StreamController<CommunicationState>.broadcast();

  final StreamController<CommunicationState> _stateController;
  CommunicationState _currentState = const CommunicationState(status: CommunicationStatus.idle);

  Stream<CommunicationState> get stateStream => _stateController.stream;
  CommunicationState get currentState => _currentState;

  void transitionTo(CommunicationStatus newStatus, {String? requestId, String? transport, String? error}) {
    if (_currentState.status == newStatus) return;

    _currentState = CommunicationState(
      status: newStatus,
      activeRequestId: requestId ?? _currentState.activeRequestId,
      activeTransport: transport ?? _currentState.activeTransport,
      lastTransitionTime: DateTime.now(),
      lastError: error,
    );

    if (!_stateController.isClosed) {
      Future<void>(() {
        if (!_stateController.isClosed) _stateController.add(_currentState);
      });
    }
  }

  Future<void> dispose() async {
    await _stateController.close();
  }
}
