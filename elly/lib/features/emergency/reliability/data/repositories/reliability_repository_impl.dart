/// reliability_repository_impl.dart
///
/// Implementation of IReliabilityRepository.

library;

import '../../domain/entities/connectivity_state.dart';
import '../../domain/entities/reliability_state.dart';
import '../../domain/entities/reliability_event.dart';
import '../../domain/entities/reliability_score.dart';
import '../../domain/repositories/i_reliability_repository.dart';
import '../services/offline_survival_engine.dart';

class ReliabilityRepositoryImpl implements IReliabilityRepository {
  ReliabilityRepositoryImpl({
    required OfflineSurvivalEngine engine,
  }) : _engine = engine;

  final OfflineSurvivalEngine _engine;

  @override
  Stream<ReliabilityState> get stateStream => _engine.stateMachine.stateStream;

  @override
  Stream<ReliabilityEvent> get eventStream => _engine.eventBus.eventStream;

  @override
  ReliabilityState get currentState => _engine.stateMachine.currentState;

  @override
  ReliabilityScore get currentScore {
    final connState = _engine.connectivityMonitor.currentState;
    final connScore = connState.isInternetAvailable ? 100 : (connState.overallStatus == OverallConnectivityStatus.degraded ? 50 : 20);

    return ReliabilityScore(
      connectivityPercent: connScore,
      queueHealthPercent: 100,
      recoveryReadinessPercent: 100,
      storageHealthPercent: 100,
      overallScore: ((connScore + 300) / 4).round(),
    );
  }

  @override
  Future<void> startEngine({required String sessionId}) async {
    await _engine.startEngine(sessionId: sessionId);
  }

  @override
  Future<void> stopEngine() async {
    await _engine.stopEngine();
  }

  @override
  Future<void> recoverSession() async {
    // Session re-hydration logic
  }
}
