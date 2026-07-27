/// readiness_providers.dart
///
/// Riverpod dependency injection definitions for EmergencyReadinessEngine and ReadinessController.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/readiness/domain/entities/readiness_report.dart';
import 'package:elly/features/emergency/readiness/domain/services/emergency_readiness_engine.dart';
import 'package:elly/features/emergency/readiness/presentation/controllers/readiness_controller.dart';

final emergencyReadinessEngineProvider = Provider<EmergencyReadinessEngine>((ref) {
  return EmergencyReadinessEngine(ref);
});

final readinessControllerProvider =
    StateNotifierProvider<ReadinessController, ReadinessReport>((ref) {
  final engine = ref.watch(emergencyReadinessEngineProvider);
  return ReadinessController(engine);
});
