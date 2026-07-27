/// session_providers.dart
///
/// Riverpod dependency injection definitions exposing engine registrations,
/// orchestrator, repository, controller, active session, timeline streams, and session state.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_engine.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_context.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_session.dart';
import 'package:elly/features/emergency/session/domain/entities/session_state.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_session_snapshot.dart';
import 'package:elly/features/emergency/session/domain/repositories/emergency_session_repository.dart';

import 'package:elly/features/emergency/session/data/orchestrator/emergency_session_orchestrator.dart';
import 'package:elly/features/emergency/session/data/repositories/emergency_session_repository_impl.dart';
import 'package:elly/features/emergency/session/presentation/controllers/emergency_session_controller.dart';

// Engine Adapter Wrappers
import 'package:elly/features/emergency/health_passport/presentation/providers/health_passport_providers.dart';
import 'package:elly/features/emergency/telemetry/presentation/providers/telemetry_providers.dart';
import 'package:elly/features/emergency/sos_circle/presentation/providers/sos_circle_providers.dart';
import 'package:elly/features/emergency/communication/presentation/controllers/emergency_communication_controller.dart';


import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';


class HealthPassportEngineAdapter implements EmergencyEngine {
  HealthPassportEngineAdapter(this.ref);
  final Ref ref;

  @override
  String get engineId => 'eng_health';
  @override
  String get engineName => 'Health Passport Engine';
  @override
  EmergencyCapability get capabilities => const EmergencyCapability();

  @override
  Future<void> initialize(EmergencyContext context) async {
    await ref.read(healthPassportControllerProvider.notifier).loadProfile();
  }

  @override
  Future<void> dispose() async {}
}

class TelemetryEngineAdapter implements EmergencyEngine {
  TelemetryEngineAdapter(this.ref);
  final Ref ref;

  @override
  String get engineId => 'eng_telemetry';
  @override
  String get engineName => 'Telemetry Engine';
  @override
  EmergencyCapability get capabilities => const EmergencyCapability(requiresLocation: true);

  @override
  Future<void> initialize(EmergencyContext context) async {
    await ref.read(telemetryControllerProvider.notifier).startSession(context.sessionId);
  }

  @override
  Future<void> dispose() async {
    await ref.read(telemetryControllerProvider.notifier).stopSession();
  }
}

class SosCircleEngineAdapter implements EmergencyEngine {
  SosCircleEngineAdapter(this.ref);
  final Ref ref;

  @override
  String get engineId => 'eng_sos_circle';
  @override
  String get engineName => 'SOS Circle Engine';
  @override
  EmergencyCapability get capabilities => const EmergencyCapability();

  @override
  Future<void> initialize(EmergencyContext context) async {
    await ref.read(sosCircleControllerProvider.notifier).triggerSOSNotifications(
          sessionId: context.sessionId,
          emergencyType: context.emergencyType,
          selectedService: 'Priority Dispatch',
        );
  }

  @override
  Future<void> dispose() async {}
}

class CommunicationEngineAdapter implements EmergencyEngine {
  CommunicationEngineAdapter(this.ref);
  final Ref ref;

  @override
  String get engineId => 'eng_communication';
  @override
  String get engineName => 'Communication Engine';
  @override
  EmergencyCapability get capabilities => const EmergencyCapability();

  @override
  Future<void> initialize(EmergencyContext context) async {
    await ref.read(emergencyCommunicationControllerProvider.notifier).executeDispatch(
          triggerSource: 'ACTIVE EMERGENCY SESSION',
        );
  }

  @override
  Future<void> dispose() async {
    ref.read(emergencyCommunicationControllerProvider.notifier).reset();
  }
}

class OfflineEngineAdapter implements EmergencyEngine {
  OfflineEngineAdapter(this.ref);
  final Ref ref;

  @override
  String get engineId => 'eng_offline';
  @override
  String get engineName => 'Offline Emergency Mode Engine';
  @override
  EmergencyCapability get capabilities => const EmergencyCapability();


  @override
  Future<void> initialize(EmergencyContext context) async {
    await ref.read(offlineRepositoryProvider).initialize();
  }

  @override
  Future<void> dispose() async {}
}

final registeredEnginesProvider = Provider<List<EmergencyEngine>>((ref) {
  return [
    HealthPassportEngineAdapter(ref),
    TelemetryEngineAdapter(ref),
    SosCircleEngineAdapter(ref),
    CommunicationEngineAdapter(ref),
    OfflineEngineAdapter(ref),
  ];
});


final emergencySessionOrchestratorProvider = Provider<EmergencySessionOrchestrator>((ref) {
  final engines = ref.watch(registeredEnginesProvider);
  return EmergencySessionOrchestrator(engines: engines);
});

final emergencySessionRepositoryProvider = Provider<EmergencySessionRepository>((ref) {
  final orchestrator = ref.watch(emergencySessionOrchestratorProvider);
  return EmergencySessionRepositoryImpl(orchestrator: orchestrator);
});

final activeEmergencySessionControllerProvider =
    StateNotifierProvider<EmergencySessionController, EmergencySession>((ref) {
  final repository = ref.watch(emergencySessionRepositoryProvider);
  return EmergencySessionController(repository, ref);
});

final currentSessionProvider = Provider<EmergencySession>((ref) {
  return ref.watch(activeEmergencySessionControllerProvider);
});

final sessionTimelineProvider = Provider<List<EmergencyTimelineEvent>>((ref) {
  final session = ref.watch(activeEmergencySessionControllerProvider);
  return session.timeline;
});

final sessionStateProvider = Provider<SessionState>((ref) {
  final session = ref.watch(activeEmergencySessionControllerProvider);
  return session.state;
});

final sessionSnapshotProvider = Provider<EmergencySessionSnapshot>((ref) {
  final session = ref.watch(activeEmergencySessionControllerProvider);
  final telemetryPoint = ref.watch(latestTelemetryPointProvider);
  final profile = ref.watch(healthProfileProvider);

  return EmergencySessionSnapshot(
    session: session,
    latestLocation: telemetryPoint,
    activeEngines: session.activeEngines,
    healthSummary: profile?.criticalSummary ?? const {},
    timelineCount: session.timeline.length,
    currentTimeline: session.timeline,
  );
});


