/// speech_controller.dart
///
/// Master presentation StateNotifier controller managing STT session transcription,
/// schema-versioned event publishing over EmergencyEventBus, and Riverpod presentation state.

library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_state.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_error.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_events.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/speech_buffer_service.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/speech_recognition_service.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';

class SpeechController extends StateNotifier<SpeechState> {
  SpeechController(
    this._ref, {
    required SpeechBufferService bufferService,
    required SpeechRecognitionService recognitionService,
  })  : _bufferService = bufferService,
        _recognitionService = recognitionService,
        super(const SpeechState()) {
    _initBufferListener();
  }

  final Ref _ref;
  final SpeechBufferService _bufferService;
  final SpeechRecognitionService _recognitionService;
  StreamSubscription<SpeechSession>? _sessionSubscription;

  void _initBufferListener() {
    _sessionSubscription = _bufferService.sessionStream.listen(
      _handleSessionReceived,
      onError: (dynamic error) {
        appLogger.error('SpeechController: Session stream error: $error');
        _handleError(SpeechErrorCategory.inferenceFailure, error.toString());
      },
    );
  }

  Future<void> _handleSessionReceived(SpeechSession session) async {
    final timestamp = DateTime.now();
    state = state.copyWith(
      status: SpeechStatus.transcribing,
      activeSessionId: session.sessionId,
      clearError: true,
    );

    // 1. Emit TranscriptionStartedPlatformEvent
    final startEvent = TranscriptionStartedPlatformEvent(
      sessionId: session.sessionId,
      timestamp: timestamp,
    );
    _publishEvent(startEvent);

    try {
      // 2. Perform STT Transcription
      final result = await _recognitionService.processSession(session);

      // 3. Emit TranscriptionCompletedPlatformEvent
      final compEvent = TranscriptionCompletedPlatformEvent(
        sessionId: session.sessionId,
        engine: result.engine,
        inferenceTimeMs: result.inferenceTimeMs,
        timestamp: DateTime.now(),
      );
      _publishEvent(compEvent);

      // 4. Emit SpeechRecognizedPlatformEvent (v1)
      final recEvent = SpeechRecognizedPlatformEvent(
        sessionId: session.sessionId,
        transcript: result.text,
        confidence: result.confidence,
        language: result.language,
        engine: result.engine,
        timestamp: DateTime.now(),
      );
      _publishEvent(recEvent);

      // 5. Update State
      state = state.copyWith(
        status: SpeechStatus.completed,
        lastTranscript: result.text,
        confidence: result.confidence,
        lastInferenceTimeMs: result.inferenceTimeMs,
      );

      appLogger.info('SpeechController: 🗣️ Transcript Result: "${result.text}" (conf: ${(result.confidence * 100).toStringAsFixed(1)}%, ${result.inferenceTimeMs}ms)');
    } on SpeechError catch (e) {
      if (e.category == SpeechErrorCategory.cancelled) {
        state = state.copyWith(status: SpeechStatus.cancelled);
      } else {
        _handleError(e.category, e.message);
      }
    } catch (e) {
      _handleError(SpeechErrorCategory.inferenceFailure, e.toString());
    }
  }

  Future<void> cancelActiveTranscription() async {
    await _recognitionService.cancelActiveRecognition();
    _bufferService.cancelBuffering();
    state = state.copyWith(status: SpeechStatus.cancelled);
    appLogger.info('SpeechController: Cancelled active STT transcription.');
  }

  void _handleError(SpeechErrorCategory category, String message, {String? sessionId}) {
    state = state.copyWith(
      status: SpeechStatus.error,
      errorCategory: category,
      errorMessage: message,
    );

    final failEvent = SpeechRecognitionFailedPlatformEvent(
      sessionId: sessionId ?? state.activeSessionId ?? 'sess_stt_unknown',
      errorCategory: category,
      errorMessage: message,
      engine: SpeechEngine.sherpaSenseVoice,
      timestamp: DateTime.now(),
    );
    _publishEvent(failEvent);

    appLogger.error('SpeechController: STT Error [${category.name}]: $message');
  }

  void _publishEvent(PlatformEvent event) {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      bus.publish(event.eventName, event.payload);
    } catch (e) {
      appLogger.warning('SpeechController: Could not publish STT event to EmergencyEventBus: $e');
    }
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _bufferService.dispose();
    _recognitionService.dispose();
    super.dispose();
  }
}
