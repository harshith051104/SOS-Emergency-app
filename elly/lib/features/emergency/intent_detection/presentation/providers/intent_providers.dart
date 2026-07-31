/// intent_providers.dart
///
/// Riverpod dependency injection definitions for Emergency Intent Detection feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/features/emergency/intent_detection/domain/interfaces/i_intent_detector.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_config.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_state.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_telemetry.dart';
import 'package:elly/features/emergency/intent_detection/data/services/detectors/rule_based_intent_detector.dart';
import 'package:elly/features/emergency/intent_detection/data/services/detectors/mock_intent_detector.dart';
import 'package:elly/features/emergency/intent_detection/data/services/intent_detection_service.dart';
import 'package:elly/features/emergency/intent_detection/presentation/controllers/intent_controller.dart';

import 'package:elly/features/emergency/voice_trigger/presentation/providers/custom_wake_word_provider.dart';

final intentConfigProvider = StateProvider<IntentConfig>((ref) {
  return const IntentConfig();
});

/// Direct Riverpod DI Selection for IntentDetector implementation.
final intentDetectorProvider = Provider<IntentDetector>((ref) {
  final config = ref.watch(intentConfigProvider);
  final customWords = ref.watch(customWakeWordsProvider);
  switch (config.detectorType) {
    case IntentProcessingMethod.ruleBased:
    case IntentProcessingMethod.localModel:
      final detector = RuleBasedIntentDetector(
        config: config,
        customWakeWords: customWords,
      );
      ref.onDispose(() => detector.dispose());
      return detector;
    case IntentProcessingMethod.mock:
      final mock = MockIntentDetector();
      ref.onDispose(() => mock.dispose());
      return mock;
  }
});

final intentDetectionServiceProvider = Provider<IntentDetectionService>((ref) {
  final detector = ref.watch(intentDetectorProvider);
  final config = ref.watch(intentConfigProvider);

  final service = IntentDetectionService(
    detector: detector,
    timeoutMs: config.maxProcessingTimeMs,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final intentControllerProvider = StateNotifierProvider<IntentController, IntentState>((ref) {
  final service = ref.watch(intentDetectionServiceProvider);

  return IntentController(
    ref,
    service: service,
  );
});

final intentTelemetryProvider = Provider<IntentTelemetry>((ref) {
  final service = ref.watch(intentDetectionServiceProvider);
  return service.telemetry;
});
