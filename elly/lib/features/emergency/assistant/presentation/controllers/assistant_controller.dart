/// assistant_controller.dart
///
/// Orchestrates the ELLY voice assistant pipeline, state machine,
/// priority queue scheduler, dynamic context prompt assembler,
/// timeline logs, and latency measurements.

library;

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/core/utils/app_logger.dart';
import '../../../packet/data/services/location_service.dart';
import '../../../packet/data/services/timeline_service.dart';
import '../../domain/entities/assistant_metrics.dart';
import '../../domain/entities/assistant_state.dart';
import '../../domain/entities/conversation_message.dart';
import '../../domain/entities/voice_event.dart';
import '../../data/services/assistant_brain.dart';
import '../../data/services/audio_session_manager.dart';
import '../../data/services/conversation_manager.dart';
import '../../data/services/conversation_policy_engine.dart';
import '../../data/services/groq_llm_service.dart';
import '../../data/services/prompt_builder.dart';
import '../../data/services/speech_recognition_service.dart';
import '../../data/services/speech_synthesis_service.dart';
import '../../data/services/voice_scheduler.dart';

class AssistantControllerState extends Equatable {
  const AssistantControllerState({
    this.state = AssistantState.initializing,
    this.messages = const [],
    this.metrics = const AssistantMetrics(),
    this.activeTextSpeech = '',
  });

  final AssistantState state;
  final List<ConversationMessage> messages;
  final AssistantMetrics metrics;
  final String activeTextSpeech;

  AssistantControllerState copyWith({
    AssistantState? state,
    List<ConversationMessage>? messages,
    AssistantMetrics? metrics,
    String? activeTextSpeech,
  }) {
    return AssistantControllerState(
      state: state ?? this.state,
      messages: messages ?? this.messages,
      metrics: metrics ?? this.metrics,
      activeTextSpeech: activeTextSpeech ?? this.activeTextSpeech,
    );
  }

  @override
  List<Object?> get props => [state, messages, metrics, activeTextSpeech];
}

class AssistantController extends StateNotifier<AssistantControllerState> {
  AssistantController({
    required ConversationManager conversationManager,
    required PromptBuilder promptBuilder,
    required ConversationPolicyEngine policyEngine,
    required SpeechRecognitionService speechRecognitionService,
    required SpeechSynthesisService speechSynthesisService,
    required GroqLlmService groqLlmService,
    required AudioSessionManager audioSessionManager,
    required TimelineService timelineService,
    required LocationService locationService,
  })  : _conversationManager = conversationManager,
        _promptBuilder = promptBuilder,
        _policyEngine = policyEngine,
        _speechRecognition = speechRecognitionService,
        _speechSynthesis = speechSynthesisService,
        _groqLlm = groqLlmService,
        _audioSession = audioSessionManager,
        _timelineService = timelineService,
        _locationService = locationService,
        super(const AssistantControllerState()) {
    
    // Initialize VoiceScheduler with audio session callbacks
    _scheduler = VoiceScheduler(
      onSpeak: _onSpeakEvent,
      onStopPlayback: _onStopPlayback,
    );

    // Initialize AssistantBrain
    _brain = AssistantBrain(
      policyEngine: _policyEngine,
      scheduler: _scheduler,
    );
  }

  final ConversationManager _conversationManager;
  final PromptBuilder _promptBuilder;
  final ConversationPolicyEngine _policyEngine;
  final SpeechRecognitionService _speechRecognition;
  final SpeechSynthesisService _speechSynthesis;
  final GroqLlmService _groqLlm;
  final AudioSessionManager _audioSession;
  final TimelineService _timelineService;
  final LocationService _locationService;

  late final VoiceScheduler _scheduler;
  late final AssistantBrain _brain;

  DateTime? _inputStartTime;

  Timer? _listeningTimer;
  bool _isAutoSessionActive = false;
  String? _activeEmergencyCategory;

  AssistantBrain get brain => _brain;
  VoiceScheduler get scheduler => _scheduler;
  bool get isAutoSessionActive => _isAutoSessionActive;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Starts continuous hands-free emergency session loop.
  /// Automatically triggers warm greeting and activates microphone loop until session ends.
  Future<void> startContinuousSession(String? category) async {
    if (!mounted) return;
    _isAutoSessionActive = true;
    _activeEmergencyCategory = category;

    appLogger.info('AssistantController: Continuous session initialized [Category: $category]');

    /* ── Voice Assistant Background Audio Loop (Commented out per user requirement) ──
    if (_conversationManager.messages.isEmpty) {
      String initialGreeting = "I am Elly, your emergency supporter. I am right here with you, and help is on the way. Tell me what is happening.";
      final catUpper = (category ?? '').toUpperCase();
      if (catUpper.contains('MEDICAL')) {
        initialGreeting = "I'm Elly, your medical emergency supporter. Emergency contacts have been notified. Tell me if you are injured or in pain.";
      } else if (catUpper.contains('POLICE') || catUpper.contains('SECURITY')) {
        initialGreeting = "I'm Elly, your safety supporter. Location tracking is active. Tell me if you are in a safe, secure spot right now.";
      } else if (catUpper.contains('FIRE')) {
        initialGreeting = "I'm Elly. Fire emergency alert is active. Please get to a safe outdoor space low under any smoke. Tell me where you are.";
      }
      
      await _handleAssistantResponse(initialGreeting);
    } else {
      await startListening();
    }
    ── End Voice Assistant Comment ── */
  }


  /// Stops continuous emergency session when SOS concludes.
  Future<void> stopContinuousSession() async {
    _isAutoSessionActive = false;
    _listeningTimer?.cancel();
    _listeningTimer = null;
    await _audioSession.stopPlayback();
    if (mounted) {
      state = state.copyWith(state: AssistantState.idle);
    }
  }

  /// Starts the voice recording session. Triggers barge-in if ELLY is currently speaking.
  Future<void> startListening() async {
    if (!mounted) return;
    _listeningTimer?.cancel();
    _inputStartTime = DateTime.now();

    // Barge-in: Interrupt active speaking or thinking immediately
    if (state.state == AssistantState.speaking || state.state == AssistantState.thinking) {
      appLogger.info('AssistantController: Barge-in triggered. Interrupting speech synthesis.');
      await _scheduler.interrupt();
      _timelineService.append(
        title: 'Speech Interrupted',
        description: 'User barge-in interrupted ELLY speech.',
      );
    }

    if (!mounted) return;
    state = state.copyWith(state: AssistantState.listening);
    await _audioSession.startRecording();


    // Extended 12-second listening window to allow user to complete their request naturally
    _listeningTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && state.state == AssistantState.listening) {
        appLogger.info('AssistantController: 12s listening timeout completed. Processing audio...');
        stopListening();
      }
    });
  }

  /// Stops voice recording, transcribes audio via Whisper, and triggers LLM chat pipeline.
  Future<void> stopListening() async {
    if (!mounted) return;
    if (state.state != AssistantState.listening) return;

    _listeningTimer?.cancel();
    _listeningTimer = null;

    if (!mounted) return;
    state = state.copyWith(state: AssistantState.transcribing);
    final filePath = await _audioSession.stopRecording();
    
    if (filePath == null) {
      if (mounted) state = state.copyWith(state: AssistantState.idle);
      _checkAutoListenLoop();
      return;
    }

    final sttStart = DateTime.now();
    final transcript = await _speechRecognition.transcribe(filePath);
    final sttEnd = DateTime.now();

    if (transcript == null || transcript.trim().isEmpty) {
      appLogger.warning('AssistantController: Empty transcript or user remained silent.');
      if (mounted) state = state.copyWith(state: AssistantState.idle);
      _checkAutoListenLoop();
      return;
    }

    // Record Whisper Latency metric
    final sttLatency = sttEnd.difference(sttStart).inMilliseconds;
    if (mounted) {
      state = state.copyWith(
        metrics: state.metrics.copyWith(
          sttLatencyMs: sttLatency,
          lastTranscript: transcript,
        ),
      );
    }

    await processInput(transcript);
  }

  void _checkAutoListenLoop() {
    if (_isAutoSessionActive && mounted) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _isAutoSessionActive && state.state == AssistantState.idle) {
          startListening();
        }
      });
    }
  }

  /// Processes text input (typed or transcribed) through the LLM pipeline.
  Future<void> processInput(String text) async {
    if (!mounted) return;
    final cleanInput = text.trim();
    if (cleanInput.isEmpty) return;

    _timelineService.append(
      title: 'User Input',
      description: cleanInput,
    );

    // 1. Save user input message
    _conversationManager.addMessage(MessageRole.user, cleanInput);
    if (!mounted) return;
    state = state.copyWith(messages: _conversationManager.messages);

    state = state.copyWith(state: AssistantState.thinking);
    final llmStart = DateTime.now();

    // 2. Sensitive Topic Filter Check
    if (_policyEngine.isSensitive(cleanInput)) {
      appLogger.info('AssistantController: Input matches sensitive rules. Triggering safety policy.');
      final response = _policyEngine.getSensitiveSafetyResponse();
      await _handleAssistantResponse(response, isSafeMode: true);
      return;
    }

    // 3. Dynamic Prompt Assembly
    final location = await _locationService.getCurrentLocation();
    if (!mounted) return;
    final systemPrompt = _promptBuilder.buildSystemPrompt(
      emergencyMode: 'Active SOS',
      selectedCategory: _activeEmergencyCategory,
      durationSeconds: 0,
      currentAddress: location.address,
      locationAccuracy: location.accuracy,
      batteryLevel: '80%',
      medicalProfileSummary: 'Asthma, Allergy: Penicillin',
      timelineEntries: _timelineService.events.map((e) => e.description).toList(),
      conversationSummary: _conversationManager.summary,
    );

    // 4. Call Groq LLM (Streaming sentence buffer)
    final sentenceBuffer = StringBuffer();
    bool firstTokenReceived = false;

    try {
      final tokenStream = _groqLlm.streamChat(_conversationManager.messages, systemPrompt: systemPrompt);

      await for (final token in tokenStream) {
        if (!mounted) return;
        if (!firstTokenReceived) {
          firstTokenReceived = true;
          final llmFirstTokenEnd = DateTime.now();
          state = state.copyWith(
            metrics: state.metrics.copyWith(
              llmLatencyMs: llmFirstTokenEnd.difference(llmStart).inMilliseconds,
            ),
          );
        }

        sentenceBuffer.write(token);
        final currentText = sentenceBuffer.toString();

        // If sentence boundary met, slice and enqueue speech synthesis
        if (currentText.contains('.') || currentText.contains('?') || currentText.contains('!')) {
          final sentence = currentText.trim();
          sentenceBuffer.clear();
          
          if (sentence.isNotEmpty) {
            await _queueSentence(sentence);
          }
        }
      }

      // Handle any leftover text in the buffer
      final remaining = sentenceBuffer.toString().trim();
      if (remaining.isNotEmpty && mounted) {
        await _queueSentence(remaining);
      }
    } catch (e) {
      // Offline fallback trigger
      if (mounted) {
        final offlineResponse = _policyEngine.getOfflineResponse(cleanInput);
        await _handleAssistantResponse(offlineResponse, isOfflineFallback: true);
      }
    }
  }

  /// Reset session and helper states.
  void reset() {
    _conversationManager.clear();
    _scheduler.clearQueue();
    _brain.reset();
    if (!mounted) return;
    state = AssistantControllerState(
      state: AssistantState.idle,
      messages: _conversationManager.messages,
    );
  }

  // ── Internal Helpers ───────────────────────────────────────────────────────

  /// Synthesizes and queues a single sentence chunk.
  /// Pre-synthesizes audio and stores the path in [VoiceEvent.audioPath] so
  /// [_onSpeakEvent] can play it directly without a second API round-trip.
  Future<void> _queueSentence(String sentence) async {
    if (!mounted) return;
    final ttsStart = DateTime.now();
    // Pre-synthesize: download audio now so it's ready by the time the
    // scheduler dequeues this event (low-latency playback).
    final audioPath = await _speechSynthesis.synthesize(sentence);
    final ttsEnd = DateTime.now();

    final ttsLatency = ttsEnd.difference(ttsStart).inMilliseconds;
    if (mounted) {
      state = state.copyWith(
        metrics: state.metrics.copyWith(
          ttsLatencyMs: ttsLatency,
          ttsCacheHits: _speechSynthesis.cacheHitsCount,
        ),
      );
    }

    final eventId = 'tts_chunk_${DateTime.now().millisecondsSinceEpoch}';
    _scheduler.queueEvent(VoiceEvent(
      id: eventId,
      text: sentence,
      priority: VoicePriority.dialogue,
      timestamp: DateTime.now(),
      audioPath: audioPath,  // carries the pre-synthesized file path
    ));
  }

  /// Handles non-streamed full responses (safe mode, offline fallback, etc.).
  Future<void> _handleAssistantResponse(
    String responseText, {
    bool isSafeMode = false,
    bool isOfflineFallback = false,
  }) async {
    final ttsStart = DateTime.now();
    await _speechSynthesis.synthesize(responseText);
    final ttsEnd = DateTime.now();


    if (mounted) {
      state = state.copyWith(
        metrics: state.metrics.copyWith(
          ttsLatencyMs: ttsEnd.difference(ttsStart).inMilliseconds,
          safetyCategory: isSafeMode ? 'sensitive_filter' : (isOfflineFallback ? 'offline' : 'safe'),
        ),
      );
    }

    _scheduler.queueEvent(VoiceEvent(
      id: 'response_${DateTime.now().millisecondsSinceEpoch}',
      text: responseText,
      priority: VoicePriority.dialogue,
      timestamp: DateTime.now(),
    ));
  }

  /// Callback registered with the VoiceScheduler to play the spoken response.
  /// Uses [event.audioPath] if pre-synthesis succeeded; falls back to a fresh
  /// API call only when the path is absent (e.g., brain-triggered events from
  /// [AssistantBrain] that bypass [_queueSentence]).
  Future<void> _onSpeakEvent(String text, bool isCritical) async {
    if (!mounted) return;
    state = state.copyWith(
      state: AssistantState.speaking,
      activeTextSpeech: text,
    );

    // Save assistant reply message in conversation manager
    _conversationManager.addMessage(MessageRole.assistant, text);
    if (!mounted) return;
    state = state.copyWith(messages: _conversationManager.messages);

    _timelineService.append(
      title: 'ELLY Spoke',
      description: text,
    );

    // Retrieve the pre-synthesized path from the current scheduler event.
    // Falls back to a fresh synthesis call only when the event carries no path
    // (i.e., events queued directly by AssistantBrain without pre-synthesis).
    final preSynthesizedPath = _scheduler.currentEventAudioPath;
    String? audioPath;

    if (preSynthesizedPath != null) {
      audioPath = preSynthesizedPath;
      appLogger.info('AssistantController: Using pre-synthesized audio: $audioPath');
    } else {
      audioPath = await _speechSynthesis.synthesize(text);
    }

    if (!mounted) return;


    final completer = Completer<void>();
    final playStart = DateTime.now();

    if (audioPath != null) {
      await _audioSession.playAudio(
        audioPath,
        fallbackText: text,
        onStart: () {
          if (!mounted) return;
          final playEnd = DateTime.now();
          state = state.copyWith(
            metrics: state.metrics.copyWith(
              playbackLatencyMs: playEnd.difference(playStart).inMilliseconds,
            ),
          );
        },
        onComplete: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
    } else {
      await _audioSession.speakText(
        text,
        onStart: () {
          if (!mounted) return;
          final playEnd = DateTime.now();
          state = state.copyWith(
            metrics: state.metrics.copyWith(
              playbackLatencyMs: playEnd.difference(playStart).inMilliseconds,
            ),
          );
        },
        onComplete: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
    }
    await completer.future;

    if (!mounted) return;

    if (_inputStartTime != null) {
      final e2eLatency = DateTime.now().difference(_inputStartTime!).inMilliseconds;
      state = state.copyWith(
        metrics: state.metrics.copyWith(
          endToEndLatencyMs: e2eLatency,
          conversationCount: state.metrics.conversationCount + 1,
          lastResponse: text,
        ),
      );
      _inputStartTime = null;
    }

    if (!mounted) return;
    state = state.copyWith(
      state: AssistantState.idle,
      activeTextSpeech: '',
    );
    _scheduler.notifyPlaybackComplete();

    // Auto-listen loop continuation when active SOS session is running
    if (_isAutoSessionActive && mounted) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _isAutoSessionActive && state.state == AssistantState.idle) {
          startListening();
        }
      });
    }
  }

  /// Callback registered with VoiceScheduler to interrupt active audio player voices.
  Future<void> _onStopPlayback() async {
    await _audioSession.stopPlayback();
    if (!mounted) return;
    state = state.copyWith(
      state: AssistantState.idle,
      activeTextSpeech: '',
    );
  }

  @override
  void dispose() {
    _scheduler.interrupt();
    super.dispose();
  }
}
