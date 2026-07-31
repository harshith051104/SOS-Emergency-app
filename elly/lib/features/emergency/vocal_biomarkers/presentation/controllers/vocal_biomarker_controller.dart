/// vocal_biomarker_controller.dart
///
/// Master presentation StateNotifier controller managing Vocal Biomarker Analysis lifecycle,
/// schema-versioned event publishing over EmergencyEventBus, and Riverpod presentation state.

library;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';

import '../../domain/entities/vocal_biomarker_state.dart';
import '../../domain/entities/vocal_biomarker_request.dart';
import '../../domain/entities/vocal_biomarker_error.dart';
import '../../domain/entities/vocal_biomarker_events.dart';
import '../../data/services/vocal_biomarker_service.dart';

class VocalBiomarkerController extends StateNotifier<VocalBiomarkerState> {
  VocalBiomarkerController(
    this._ref, {
    required VocalBiomarkerService service,
  })  : _service = service,
        super(const VocalBiomarkerState()) {
    _initEventBusListener();
  }

  final Ref _ref;
  final VocalBiomarkerService _service;
  StreamSubscription<PlatformEvent>? _busSubscription;

  void _initEventBusListener() {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      _busSubscription = bus.events.listen((event) {
        if (event.eventName == 'SpeechRecognized' || event.eventName == 'SpeechEnded') {
          _handleAudioEvent(event);
        }
      });
    } catch (e) {
      appLogger.warning('VocalBiomarkerController: Could not subscribe to EmergencyEventBus: $e');
    }
  }

  Future<void> _handleAudioEvent(PlatformEvent event) async {
    final payload = event.payload;
    final sessionId = payload['sessionId'] as String? ?? 'sess_bio_${DateTime.now().millisecondsSinceEpoch}';

    final pcmBytes = payload['pcmData'] as Uint8List? ?? Uint8List(16000 * 2);
    final audioBuffer = AudioBuffer(pcmData: pcmBytes);

    final request = VocalBiomarkerRequest(
      sessionId: sessionId,
      audioBuffer: audioBuffer,
      timestamp: DateTime.now(),
    );

    await analyzeBiomarkers(request);
  }

  Future<void> analyzeBiomarkers(VocalBiomarkerRequest request) async {
    final timestamp = DateTime.now();

    state = state.copyWith(
      status: VocalBiomarkerStatus.analyzing,
      activeSessionId: request.sessionId,
      clearError: true,
    );

    // 1. Emit VocalBiomarkerStartedPlatformEvent
    final startEvent = VocalBiomarkerStartedPlatformEvent(
      sessionId: request.sessionId,
      timestamp: timestamp,
    );
    _publishEvent(startEvent);

    try {
      // 2. Process Feature Extraction
      final result = await _service.processRequest(request);

      // 3. Emit VocalBiomarkerCompletedPlatformEvent
      final compEvent = VocalBiomarkerCompletedPlatformEvent(
        sessionId: request.sessionId,
        processingMethod: result.processingMethod,
        dspVersion: result.dspVersion,
        algorithmVersion: result.algorithmVersion,
        processingTimeMs: result.processingTimeMs,
        timestamp: DateTime.now(),
      );
      _publishEvent(compEvent);

      // 4. Emit VocalBiomarkerAnalyzedPlatformEvent (v1)
      final analyzedEvent = VocalBiomarkerAnalyzedPlatformEvent(
        result: result,
        timestamp: DateTime.now(),
      );
      _publishEvent(analyzedEvent);

      // 5. Update State
      state = state.copyWith(
        status: VocalBiomarkerStatus.completed,
        lastResult: result,
        telemetry: _service.telemetry,
      );

      appLogger.info(
        'VocalBiomarkerController: 🎙️ Vocal Biomarkers Extracted: Stability=${(result.voiceStability * 100).toStringAsFixed(1)}%, '
        'Tension=${(result.vocalTension * 100).toStringAsFixed(1)}%, Jitter=${result.jitter}%, Shimmer=${result.shimmer}%, '
        'HNR=${result.harmonicsToNoiseRatio}dB (${result.processingTimeMs}ms)',
      );
    } on VocalBiomarkerError catch (e) {
      _handleError(e.category, e.message);
    } catch (e) {
      _handleError(VocalBiomarkerErrorCategory.featureExtractionFailure, e.toString());
    }
  }

  void _handleError(VocalBiomarkerErrorCategory category, String message) {
    state = state.copyWith(
      status: VocalBiomarkerStatus.failed,
      errorCategory: category,
      errorMessage: message,
      telemetry: _service.telemetry,
    );

    appLogger.error('VocalBiomarkerController: Analysis Error [${category.name}]: $message');
  }

  void _publishEvent(PlatformEvent event) {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      bus.publish(event.eventName, event.payload);
    } catch (e) {
      appLogger.warning('VocalBiomarkerController: Could not publish Biomarker event to EmergencyEventBus: $e');
    }
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
