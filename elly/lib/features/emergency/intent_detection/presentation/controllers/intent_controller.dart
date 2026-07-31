/// intent_controller.dart
///
/// Master presentation StateNotifier controller managing intent classification lifecycle,
/// schema-versioned event publishing over EmergencyEventBus, and Riverpod presentation state.

library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_state.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_error.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/intent_events.dart';
import 'package:elly/features/emergency/intent_detection/data/services/intent_detection_service.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';

class IntentController extends StateNotifier<IntentState> {
  IntentController(
    this._ref, {
    required IntentDetectionService service,
  })  : _service = service,
        super(const IntentState()) {
    _initEventBusListener();
  }

  final Ref _ref;
  final IntentDetectionService _service;
  StreamSubscription<PlatformEvent>? _busSubscription;

  void _initEventBusListener() {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      _busSubscription = bus.events.listen((event) {
        if (event.eventName == 'SpeechRecognized') {
          _handleSpeechRecognizedEvent(event);
        }
      });
    } catch (e) {
      appLogger.warning('IntentController: Could not subscribe to EmergencyEventBus: $e');
    }
  }

  Future<void> _handleSpeechRecognizedEvent(PlatformEvent event) async {
    final payload = event.payload;
    final sessionId = payload['sessionId'] as String? ?? 'sess_stt_unknown';
    final transcriptText = payload['transcript'] as String? ?? '';
    final confidence = (payload['confidence'] as num?)?.toDouble() ?? 0.0;
    final language = payload['language'] as String? ?? 'en';
    final engineName = payload['engine'] as String? ?? 'whisper';

    final speechResult = SpeechRecognitionResult(
      text: transcriptText,
      confidence: confidence,
      durationMs: 0,
      language: language,
      inferenceTimeMs: 0,
      engine: SpeechEngine.values.firstWhere(
        (e) => e.name == engineName,
        orElse: () => SpeechEngine.sherpaSenseVoice,
      ),
      timestamp: DateTime.now(),
    );

    await analyzeTranscript(speechResult, sessionId: sessionId);
  }

  Future<void> analyzeTranscript(SpeechRecognitionResult transcript, {String? sessionId}) async {
    final activeSessionId = sessionId ?? transcript.timestamp.millisecondsSinceEpoch.toString();
    final timestamp = DateTime.now();

    state = state.copyWith(
      status: IntentStatus.analyzing,
      activeSessionId: activeSessionId,
      clearError: true,
    );

    // 1. Emit IntentDetectionStartedPlatformEvent
    final startEvent = IntentDetectionStartedPlatformEvent(
      sessionId: activeSessionId,
      timestamp: timestamp,
    );
    _publishEvent(startEvent);

    try {
      // 2. Process Intent Classification
      final result = await _service.processTranscript(transcript);

      // 3. Emit IntentDetectionCompletedPlatformEvent
      final compEvent = IntentDetectionCompletedPlatformEvent(
        sessionId: activeSessionId,
        processingMethod: result.processingMethod,
        detectorVersion: result.detectorVersion,
        processingTimeMs: result.processingTimeMs,
        timestamp: DateTime.now(),
      );
      _publishEvent(compEvent);

      // 4. Emit IntentDetectedPlatformEvent (v1)
      final detEvent = IntentDetectedPlatformEvent(
        sessionId: activeSessionId,
        intent: result.intent,
        confidence: result.confidence,
        language: result.language,
        processingMethod: result.processingMethod,
        detectorVersion: result.detectorVersion,
        timestamp: DateTime.now(),
      );
      _publishEvent(detEvent);

      // 5. Update State
      state = state.copyWith(
        status: IntentStatus.completed,
        lastResult: result,
      );

      appLogger.info('IntentController: 🎯 Intent Result: ${result.intent.name} (conf: ${(result.confidence * 100).toStringAsFixed(1)}%, ${result.processingTimeMs}ms)');
    } on IntentError catch (e) {
      _handleError(e.category, e.message);
    } catch (e) {
      _handleError(IntentErrorCategory.parsingError, e.toString());
    }
  }

  void _handleError(IntentErrorCategory category, String message) {
    state = state.copyWith(
      status: IntentStatus.error,
      errorCategory: category,
      errorMessage: message,
    );

    appLogger.error('IntentController: Intent Error [${category.name}]: $message');
  }

  void _publishEvent(PlatformEvent event) {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      bus.publish(event.eventName, event.payload);
    } catch (e) {
      appLogger.warning('IntentController: Could not publish Intent event to EmergencyEventBus: $e');
    }
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
