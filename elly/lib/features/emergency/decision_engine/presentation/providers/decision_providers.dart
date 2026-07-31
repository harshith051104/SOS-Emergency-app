/// decision_providers.dart
///
/// Riverpod dependency injection providers for the Multi-Signal Decision Engine feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/decision_config.dart';
import '../../domain/entities/decision_state.dart';
import '../../domain/entities/decision_telemetry.dart';
import '../../domain/interfaces/i_decision_engine.dart';
import '../../data/engines/rule_based_decision_engine.dart';
import '../../data/services/decision_service.dart';
import '../controllers/decision_controller.dart';

/// Provider for Decision Engine Configuration
final decisionConfigProvider = Provider<DecisionConfig>((ref) {
  return const DecisionConfig();
});

/// Provider for the active DecisionEngine implementation
final decisionEngineProvider = Provider<DecisionEngine>((ref) {
  final config = ref.watch(decisionConfigProvider);
  final engine = RuleBasedDecisionEngine(config: config);
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Provider for the DecisionService
final decisionServiceProvider = Provider<DecisionService>((ref) {
  final engine = ref.watch(decisionEngineProvider);
  final config = ref.watch(decisionConfigProvider);
  final service = DecisionService(engine: engine, config: config);
  ref.onDispose(() => service.dispose());
  return service;
});

/// StateNotifierProvider for the DecisionController
final decisionControllerProvider =
    StateNotifierProvider<DecisionController, DecisionState>((ref) {
  final service = ref.watch(decisionServiceProvider);
  return DecisionController(ref, service: service);
});

/// Provider for current Decision Engine Telemetry
final decisionTelemetryProvider = Provider<DecisionTelemetry>((ref) {
  return ref.watch(decisionControllerProvider).telemetry;
});
