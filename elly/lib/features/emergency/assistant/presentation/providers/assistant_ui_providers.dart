/// assistant_ui_providers.dart
///
/// Exposes the UI-bound state and controller providers for the voice assistant.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/assistant_providers.dart';
import '../controllers/assistant_controller.dart';
import '../../../packet/presentation/providers/packet_providers.dart';

final assistantControllerProvider =
    StateNotifierProvider<AssistantController, AssistantControllerState>((ref) {
  return AssistantController(
    conversationManager: ref.watch(conversationManagerProvider),
    promptBuilder: ref.watch(promptBuilderProvider),
    policyEngine: ref.watch(conversationPolicyEngineProvider),
    speechRecognitionService: ref.watch(speechRecognitionServiceProvider),
    speechSynthesisService: ref.watch(speechSynthesisServiceProvider),
    groqLlmService: ref.watch(groqLlmServiceProvider),
    audioSessionManager: ref.watch(audioSessionManagerProvider),
    timelineService: ref.watch(timelineServiceProvider),
    locationService: ref.watch(locationServiceProvider),
  );
});
