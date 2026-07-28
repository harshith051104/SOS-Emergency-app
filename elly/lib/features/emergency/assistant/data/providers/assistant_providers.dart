/// assistant_providers.dart
///
/// Riverpod provider definitions for the Voice Assistant feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../services/audio_session_manager.dart';
import '../services/speech_recognition_service.dart';
import '../services/speech_synthesis_service.dart';
import '../services/groq_llm_service.dart';
import '../services/prompt_builder.dart';
import '../services/conversation_policy_engine.dart';
import '../services/conversation_manager.dart';

/// Exposes the secure Groq API key injected via build args or environment.
final groqApiKeyProvider = Provider<String>((ref) {
  return const String.fromEnvironment('GROQ_API_KEY');
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return client;
});

final audioSessionManagerProvider = Provider<AudioSessionManager>((ref) {
  final manager = AudioSessionManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final conversationManagerProvider = Provider<ConversationManager>((ref) {
  return ConversationManager();
});

final promptBuilderProvider = Provider<PromptBuilder>((ref) {
  return const PromptBuilder();
});

final conversationPolicyEngineProvider = Provider<ConversationPolicyEngine>((ref) {
  return const ConversationPolicyEngine();
});

final speechRecognitionServiceProvider = Provider<SpeechRecognitionService>((ref) {
  return GroqSpeechRecognitionService(
    apiKey: ref.watch(groqApiKeyProvider),
    model: 'whisper-large-v3-turbo',
    httpClient: ref.watch(httpClientProvider),
  );
});

final speechSynthesisServiceProvider = Provider<SpeechSynthesisService>((ref) {
  return GroqSpeechSynthesisService(
    apiKey: ref.watch(groqApiKeyProvider),
    model: 'orpheus-v1',
    voice: 'autumn',
    httpClient: ref.watch(httpClientProvider),
  );
});

final groqLlmServiceProvider = Provider<GroqLlmService>((ref) {
  return GroqLlmService(
    apiKey: ref.watch(groqApiKeyProvider),
    model: 'llama-3.1-8b-instant',
    httpClient: ref.watch(httpClientProvider),
  );
});
