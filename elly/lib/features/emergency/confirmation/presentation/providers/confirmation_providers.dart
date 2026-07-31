/// confirmation_providers.dart
///
/// Riverpod dependency injection providers for the Confirmation Engine feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/confirmation_config.dart';
import '../../domain/entities/confirmation_state.dart';
import '../../domain/entities/confirmation_telemetry.dart';
import '../../domain/interfaces/i_confirmation_engine.dart';
import '../../data/engines/rule_based_confirmation_engine.dart';
import '../../data/services/confirmation_service.dart';
import '../controllers/confirmation_controller.dart';

/// Provider for Confirmation Engine Configuration
final confirmationConfigProvider = Provider<ConfirmationConfig>((ref) {
  return const ConfirmationConfig();
});

/// Provider for the active ConfirmationEngine implementation
final confirmationEngineProvider = Provider<ConfirmationEngine>((ref) {
  final engine = RuleBasedConfirmationEngine();
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Provider for the ConfirmationService
final confirmationServiceProvider = Provider<ConfirmationService>((ref) {
  final engine = ref.watch(confirmationEngineProvider);
  final config = ref.watch(confirmationConfigProvider);
  final service = ConfirmationService(engine: engine, config: config);
  ref.onDispose(() => service.dispose());
  return service;
});

/// StateNotifierProvider for the ConfirmationController
final confirmationControllerProvider =
    StateNotifierProvider<ConfirmationController, ConfirmationState>((ref) {
  final service = ref.watch(confirmationServiceProvider);
  return ConfirmationController(ref, service: service);
});

/// Provider for current Confirmation Telemetry
final confirmationTelemetryProvider = Provider<ConfirmationTelemetry>((ref) {
  return ref.watch(confirmationControllerProvider).telemetry;
});
