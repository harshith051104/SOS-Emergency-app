/// i_reliability_repository.dart
///
/// Interface orchestrating the entire Reliability Subsystem.

library;

import '../entities/reliability_state.dart';
import '../entities/reliability_event.dart';
import '../entities/reliability_score.dart';

abstract class IReliabilityRepository {
  Stream<ReliabilityState> get stateStream;
  Stream<ReliabilityEvent> get eventStream;

  ReliabilityState get currentState;
  ReliabilityScore get currentScore;

  Future<void> startEngine({required String sessionId});
  Future<void> stopEngine();
  Future<void> recoverSession();
}
