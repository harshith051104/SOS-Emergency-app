/// emergency_providers.dart
///
/// Riverpod providers for the Emergency feature.
/// All DI wiring lives here — widgets and controllers reference these
/// providers instead of constructing dependencies directly.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/emergency_local_datasource.dart';
import '../../data/repositories/emergency_repository_impl.dart';
import '../../domain/entities/emergency_config.dart';
import '../../domain/entities/emergency_event.dart';
import '../../domain/enums/emergency_status.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../../domain/services/emergency_risk_evaluator.dart';
import '../../domain/usecases/cancel_emergency_usecase.dart';
import '../../domain/usecases/create_emergency_usecase.dart';
import '../../domain/usecases/get_emergency_state_usecase.dart';
import '../controllers/emergency_controller.dart';
import '../../../responders/presentation/providers/responder_providers.dart';

import '../../../packet/presentation/providers/packet_providers.dart';

// ── Infrastructure Providers ──────────────────────────────────────────────────

/// Provides the in-memory local data source.
final emergencyLocalDataSourceProvider =
    Provider<EmergencyLocalDataSource>((ref) {
  return EmergencyLocalDataSourceImpl();
});

/// Provides the concrete [EmergencyRepository] implementation.
final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepositoryImpl(
    localDataSource: ref.watch(emergencyLocalDataSourceProvider),
  );
});

// ── Use Case Providers ────────────────────────────────────────────────────────

/// Provides [CreateEmergencyUseCase].
final createEmergencyUseCaseProvider = Provider<CreateEmergencyUseCase>((ref) {
  return CreateEmergencyUseCase(ref.watch(emergencyRepositoryProvider));
});

/// Provides [CancelEmergencyUseCase].
final cancelEmergencyUseCaseProvider = Provider<CancelEmergencyUseCase>((ref) {
  return CancelEmergencyUseCase(ref.watch(emergencyRepositoryProvider));
});

/// Provides [GetEmergencyStateUseCase].
final getEmergencyStateUseCaseProvider =
    Provider<GetEmergencyStateUseCase>((ref) {
  return GetEmergencyStateUseCase(ref.watch(emergencyRepositoryProvider));
});

// ── Configuration Provider ────────────────────────────────────────────────────

/// Provides the active [EmergencyConfig].
/// Override in tests to customise countdown duration, confirmationDuration, etc.
final emergencyConfigProvider = Provider<EmergencyConfig>((ref) {
  return const EmergencyConfig();
});

// ── Risk Evaluator Provider ───────────────────────────────────────────────────

/// Provides the [EmergencyRiskEvaluator] implementation.
///
/// Phase 1: [MockEmergencyRiskEvaluator] always returns false.
/// Phase 2+: Replace with a real AI/ML risk evaluator.
final emergencyRiskEvaluatorProvider = Provider<EmergencyRiskEvaluator>((ref) {
  return const MockEmergencyRiskEvaluator();
});

// ── Controller Provider ───────────────────────────────────────────────────────

/// The primary [EmergencyController] that drives all UI state transitions.
final emergencyControllerProvider =
    StateNotifierProvider<EmergencyController, EmergencyControllerState>((ref) {
  return EmergencyController(
    createEmergencyUseCase: ref.watch(createEmergencyUseCaseProvider),
    cancelEmergencyUseCase: ref.watch(cancelEmergencyUseCaseProvider),
    getRespondersUseCase: ref.watch(getRespondersUseCaseProvider),
    config: ref.watch(emergencyConfigProvider),
    riskEvaluator: ref.watch(emergencyRiskEvaluatorProvider),
    locationService: ref.watch(locationServiceProvider),
  );
});

// ── Convenience Selectors ─────────────────────────────────────────────────────

/// Watches only the [EmergencyStatus] — avoids rebuilds when other
/// state fields change.
final emergencyStatusProvider = Provider<EmergencyStatus>((ref) {
  return ref.watch(emergencyControllerProvider).status;
});

/// Watches only the active [EmergencyEvent] (may be null).
final activeEmergencyEventProvider = Provider<EmergencyEvent?>((ref) {
  return ref.watch(emergencyControllerProvider).activeEvent;
});

/// Watches the current countdown value.
final countdownValueProvider = Provider<int>((ref) {
  return ref.watch(emergencyControllerProvider).countdownValue;
});
