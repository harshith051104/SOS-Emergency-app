/// reliability_provider.dart
///
/// Riverpod Providers for Phase 1.2 Offline Survival & Disconnect Protection.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/connectivity_state.dart';
import '../../domain/entities/network_quality.dart';
import '../../domain/entities/network_capability_matrix.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/entities/reliability_state.dart';
import '../../domain/entities/reliability_event.dart';
import '../../domain/entities/reliability_score.dart';
import '../../domain/repositories/i_reliability_repository.dart';
import '../../domain/repositories/i_queue_repository.dart';
import '../../domain/repositories/i_sync_repository.dart';
import '../../domain/usecases/start_reliability_engine_usecase.dart';
import '../../domain/usecases/stop_reliability_engine_usecase.dart';
import '../../domain/usecases/enqueue_emergency_item_usecase.dart';
import '../../domain/usecases/synchronize_queue_usecase.dart';
import '../../domain/usecases/recover_reliability_session_usecase.dart';
import '../../domain/usecases/get_reliability_status_usecase.dart';
import '../../data/services/offline_survival_engine.dart';
import '../../data/repositories/reliability_repository_impl.dart';
import '../../data/repositories/queue_repository_impl.dart';
import '../../data/repositories/sync_repository_impl.dart';

final offlineSurvivalEngineProvider = Provider<OfflineSurvivalEngine>((ref) {
  final engine = OfflineSurvivalEngine();
  ref.onDispose(() => engine.stopEngine());
  return engine;
});

final reliabilityRepositoryProvider = Provider<IReliabilityRepository>((ref) {
  final engine = ref.watch(offlineSurvivalEngineProvider);
  return ReliabilityRepositoryImpl(engine: engine);
});

final queueRepositoryProvider = Provider<IQeueueRepository>((ref) {
  final engine = ref.watch(offlineSurvivalEngineProvider);
  return QueueRepositoryImpl(queueManager: engine.queueManager);
});

final syncRepositoryProvider = Provider<ISyncRepository>((ref) {
  final engine = ref.watch(offlineSurvivalEngineProvider);
  return SyncRepositoryImpl(syncEngine: engine.syncEngine);
});

final startReliabilityEngineUseCaseProvider = Provider<StartReliabilityEngineUseCase>((ref) {
  return StartReliabilityEngineUseCase(ref.watch(reliabilityRepositoryProvider));
});

final stopReliabilityEngineUseCaseProvider = Provider<StopReliabilityEngineUseCase>((ref) {
  return StopReliabilityEngineUseCase(ref.watch(reliabilityRepositoryProvider));
});

final enqueueEmergencyItemUseCaseProvider = Provider<EnqueueEmergencyItemUseCase>((ref) {
  return EnqueueEmergencyItemUseCase(ref.watch(queueRepositoryProvider));
});

final synchronizeQueueUseCaseProvider = Provider<SynchronizeQueueUseCase>((ref) {
  return SynchronizeQueueUseCase(ref.watch(syncRepositoryProvider));
});

final recoverReliabilitySessionUseCaseProvider = Provider<RecoverReliabilitySessionUseCase>((ref) {
  return RecoverReliabilitySessionUseCase(ref.watch(reliabilityRepositoryProvider));
});

final getReliabilityStatusUseCaseProvider = Provider<GetReliabilityStatusUseCase>((ref) {
  return GetReliabilityStatusUseCase(ref.watch(reliabilityRepositoryProvider));
});

final reliabilityStateStreamProvider = StreamProvider<ReliabilityState>((ref) {
  final repo = ref.watch(reliabilityRepositoryProvider);
  return repo.stateStream;
});

final reliabilityEventStreamProvider = StreamProvider<ReliabilityEvent>((ref) {
  final repo = ref.watch(reliabilityRepositoryProvider);
  return repo.eventStream;
});

final connectivityStateStreamProvider = StreamProvider<ConnectivityState>((ref) {
  final engine = ref.watch(offlineSurvivalEngineProvider);
  return engine.connectivityMonitor.connectivityStream;
});

final networkQualityStreamProvider = StreamProvider<NetworkQuality>((ref) {
  final engine = ref.watch(offlineSurvivalEngineProvider);
  return engine.qualityMonitor.qualityStream;
});

final networkCapabilityStreamProvider = StreamProvider<NetworkCapabilityMatrix>((ref) {
  final engine = ref.watch(offlineSurvivalEngineProvider);
  return engine.qualityMonitor.capabilityStream;
});

final syncStatusStreamProvider = StreamProvider<SyncStatus>((ref) {
  final engine = ref.watch(offlineSurvivalEngineProvider);
  return engine.syncEngine.syncStatusStream;
});

final reliabilityScoreProvider = Provider<ReliabilityScore>((ref) {
  final repo = ref.watch(reliabilityRepositoryProvider);
  return repo.currentScore;
});
