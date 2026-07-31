/// session_providers.dart
///
/// Riverpod dependency injection providers for Phase 8 Emergency Session Activation feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/emergency_session_config.dart';
import '../../domain/entities/emergency_session_state.dart';
import '../../domain/entities/emergency_execution_telemetry.dart';
import '../../domain/interfaces/emergency_action.dart';
import '../../domain/interfaces/i_emergency_execution_engine.dart';
import '../../data/actions/send_sms_action.dart';
import '../../data/actions/phone_call_action.dart';
import '../../data/actions/location_sharing_action.dart';
import '../../data/actions/medical_profile_action.dart';
import '../../data/actions/emergency_timeline_action.dart';
import '../../data/actions/emergency_notification_action.dart';
import '../../data/engines/rule_based_execution_engine.dart';
import '../../data/services/emergency_session_service.dart';
import '../../data/orchestrator/emergency_session_orchestrator.dart';
import '../../data/repositories/emergency_session_repository_impl.dart';
import '../../domain/repositories/emergency_session_repository.dart';
import '../../domain/entities/emergency_session_snapshot.dart';
import '../controllers/emergency_session_controller.dart';

/// Provider for Emergency Session Configuration
final emergencySessionConfigProvider = Provider<EmergencySessionConfig>((ref) {
  return const EmergencySessionConfig();
});

/// Provider for registered pluggable EmergencyAction pipeline
final emergencyActionsProvider = Provider<List<EmergencyAction>>((ref) {
  return [
    SendSmsAction(),
    PhoneCallAction(),
    LocationSharingAction(),
    MedicalProfileAction(),
    EmergencyTimelineAction(),
    EmergencyNotificationAction(),
  ];
});

/// Provider for the active EmergencyExecutionEngine implementation
final emergencyExecutionEngineProvider = Provider<EmergencyExecutionEngine>((ref) {
  final actions = ref.watch(emergencyActionsProvider);
  final config = ref.watch(emergencySessionConfigProvider);
  final engine = RuleBasedExecutionEngine(actions: actions, config: config);
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Provider for the EmergencySessionService
final emergencySessionServiceProvider = Provider<EmergencySessionService>((ref) {
  final engine = ref.watch(emergencyExecutionEngineProvider);
  final config = ref.watch(emergencySessionConfigProvider);
  final service = EmergencySessionService(engine: engine, config: config);
  ref.onDispose(() => service.dispose());
  return service;
});

/// StateNotifierProvider for the Phase 8 EmergencySessionController.
/// Named 'active' to disambiguate from the Phase 7 SOS countdown controller
/// which has its own emergencySessionControllerProvider in sos/presentation/.
final activeEmergencySessionControllerProvider =
    StateNotifierProvider<EmergencySessionController, EmergencySessionState>((ref) {
  final service = ref.watch(emergencySessionServiceProvider);
  return EmergencySessionController(ref, service: service);
});

/// Provider for current Emergency Execution Telemetry
final emergencyExecutionTelemetryProvider = Provider<EmergencyExecutionTelemetry>((ref) {
  return ref.watch(activeEmergencySessionControllerProvider).telemetry;
});

final emergencySessionOrchestratorProvider = Provider<EmergencySessionOrchestrator>((ref) {
  return EmergencySessionOrchestrator(engines: const []);
});

final emergencySessionRepositoryProvider = Provider<EmergencySessionRepository>((ref) {
  final orchestrator = ref.watch(emergencySessionOrchestratorProvider);
  return EmergencySessionRepositoryImpl(orchestrator: orchestrator);
});

final sessionSnapshotProvider = Provider<EmergencySessionSnapshot>((ref) {
  final repo = ref.watch(emergencySessionRepositoryProvider);
  final session = repo.currentSession;
  return EmergencySessionSnapshot(
    session: session,
    timelineCount: 0,
  );
});
