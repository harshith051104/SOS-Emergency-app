/// decision_controller.dart
///
/// Master presentation StateNotifier controller managing Multi-Signal Decision Engine lifecycle,
/// evidence aggregation, Evidence Timeline logging, and event publishing over EmergencyEventBus.

library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent.dart';
import 'package:elly/features/emergency/intent_detection/domain/entities/emergency_intent_result.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';
import 'package:elly/features/emergency/vocal_biomarkers/domain/entities/vocal_biomarker_result.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';

import '../../domain/entities/decision_state.dart';
import '../../domain/entities/emergency_decision_request.dart';
import '../../domain/entities/decision_error.dart';
import '../../domain/entities/decision_events.dart';
import '../../data/services/decision_service.dart';

class DecisionController extends StateNotifier<DecisionState> {
  DecisionController(
    this._ref, {
    required DecisionService service,
  })  : _service = service,
        super(const DecisionState()) {
    _initEventBusListener();
  }

  final Ref _ref;
  final DecisionService _service;
  StreamSubscription<PlatformEvent>? _busSubscription;
  Timer? _debounceTimer;  // prevents duplicate evaluations when multiple signals arrive together

  // In-memory evidence cache per sessionId
  final Map<String, EmergencyDecisionRequest> _sessionRequests = {};
  final List<String> _evidenceTimeline = [];

  void _initEventBusListener() {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      _busSubscription = bus.events.listen((event) {
        _handlePipelineEvent(event);
      });
    } catch (e) {
      appLogger.warning('DecisionController: Could not subscribe to EmergencyEventBus: $e');
    }
  }

  void _handlePipelineEvent(PlatformEvent event) {
    final now = DateTime.now();
    final payload = event.payload;
    final sessionId = payload['sessionId'] as String? ?? state.activeSessionId ?? 'sess_dec_${now.millisecondsSinceEpoch}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final existing = _sessionRequests[sessionId] ?? EmergencyDecisionRequest(sessionId: sessionId, timestamp: now);

    bool shouldEvaluate = false;
    EmergencyDecisionRequest nextRequest = existing;

    switch (event.eventName) {
      case 'SpeechDetected':
      case 'VoiceDetected':
        _addTimelineEntry('$timeStr — 🗣️ Voice Detected (VAD)');
        break;

      case 'SpeechRecognized':
        final transcript = payload['transcript'] as String? ?? '';
        _addTimelineEntry('$timeStr — 📜 Transcript Ready: "$transcript"');
        nextRequest = _copyRequestWith(existing, transcript: transcript);
        break;

      case 'IntentDetected':
        final intentConfidence = (payload['confidence'] as num?)?.toDouble() ?? (payload['confidenceScore'] as num?)?.toDouble() ?? 0.0;
        final intentName = payload['intent'] as String? ?? 'emergency';
        final matchedKw = payload['matchedKeyword'] as String?;
        _addTimelineEntry('$timeStr — 🎯 Intent Ready: ${matchedKw ?? intentName} (${(intentConfidence * 100).toInt()}%)');

        final intentResult = EmergencyIntentResult(
          sessionId: sessionId,
          intent: EmergencyIntent.values.firstWhere(
            (i) => i.name == intentName,
            orElse: () => EmergencyIntent.emergency,
          ),
          confidence: intentConfidence,
          processingTimeMs: (payload['processingTimeMs'] as num?)?.toInt() ?? 5,
          language: payload['language'] as String? ?? 'en',
          processingMethod: IntentProcessingMethod.ruleBased,
          matchedPhrases: matchedKw != null ? [matchedKw] : const [],
          timestamp: now,
        );

        nextRequest = _copyRequestWith(existing, intentResult: intentResult, intentTimestamp: now);
        shouldEvaluate = true;
        break;

      case 'SpeakerVerified':
      case 'SpeakerVerificationCompleted':
        final match = payload['match'] as bool? ?? false;
        final spkConfidence = (payload['confidence'] as num?)?.toDouble() ?? 0.0;
        _addTimelineEntry('$timeStr — 👤 Speaker Verified: ${match ? 'OWNER MATCH' : 'UNMATCHED'} (${(spkConfidence * 100).toInt()}%)');

        final speakerResult = SpeakerVerificationResult(
          sessionId: sessionId,
          match: match,
          confidence: spkConfidence,
          profileId: payload['profileId'] as String? ?? 'prof_user',
          processingTimeMs: (payload['processingTimeMs'] as num?)?.toInt() ?? 10,
          embeddingVersion: payload['embeddingVersion'] as String? ?? 'v1.0.0-mock',
          processingMethod: SpeakerVerificationMethod.embedding,
          timestamp: now,
        );

        nextRequest = _copyRequestWith(existing, speakerResult: speakerResult, speakerTimestamp: now);
        shouldEvaluate = true;
        break;

      case 'VocalBiomarkerAnalyzed':
      case 'VocalBiomarkerCompleted':
        final stability = (payload['voiceStability'] as num?)?.toDouble() ?? 0.80;
        final tension = (payload['vocalTension'] as num?)?.toDouble() ?? 0.20;
        final bioConfidence = (payload['confidence'] as num?)?.toDouble() ?? 0.90;
        _addTimelineEntry('$timeStr — 🎙️ Biomarkers Ready: Stability ${(stability * 100).toInt()}%, Tension ${(tension * 100).toInt()}%');

        final biomarkerResult = VocalBiomarkerResult(
          sessionId: sessionId,
          vocalTension: tension,
          speechInstability: (payload['speechInstability'] as num?)?.toDouble() ?? 0.20,
          breathingIrregularity: (payload['breathingIrregularity'] as num?)?.toDouble() ?? 0.15,
          pitchVariability: (payload['pitchVariability'] as num?)?.toDouble() ?? 12.0,
          energyVariability: (payload['energyVariability'] as num?)?.toDouble() ?? 0.30,
          jitter: (payload['jitter'] as num?)?.toDouble() ?? 1.0,
          shimmer: (payload['shimmer'] as num?)?.toDouble() ?? 2.5,
          harmonicsToNoiseRatio: (payload['harmonicsToNoiseRatio'] as num?)?.toDouble() ?? 22.0,
          spectralCentroid: (payload['spectralCentroid'] as num?)?.toDouble() ?? 1400.0,
          voiceStability: stability,
          confidence: bioConfidence,
          processingTimeMs: (payload['processingTimeMs'] as num?)?.toInt() ?? 5,
          processingMethod: payload['processingMethod'] as String? ?? 'FEATURE_BASED_DSP',
          dspVersion: payload['dspVersion'] as String? ?? 'v1.0.0-dsp',
          algorithmVersion: payload['algorithmVersion'] as String? ?? 'v1.0.0-acoustic',
          timestamp: now,
        );

        nextRequest = _copyRequestWith(existing, biomarkerResult: biomarkerResult, biomarkerTimestamp: now);
        shouldEvaluate = true;
        break;
    }

    _sessionRequests[sessionId] = nextRequest;

    if (shouldEvaluate) {
      // Debounce: cancel any pending evaluation and reschedule.
      // This collapses intent + speaker + biomarker arriving in the same
      // ms window into a single decision run.
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 80), () {
        final latest = _sessionRequests[sessionId];
        if (latest != null) evaluateDecision(latest);
      });
    }
  }

  Future<void> evaluateDecision(EmergencyDecisionRequest request) async {
    final timestamp = DateTime.now();

    state = state.copyWith(
      status: DecisionStatus.evaluating,
      activeSessionId: request.sessionId,
      evidenceTimeline: List.from(_evidenceTimeline),
      clearError: true,
    );

    // 1. Emit DecisionStartedPlatformEvent
    final startEvent = DecisionStartedPlatformEvent(
      sessionId: request.sessionId,
      timestamp: timestamp,
    );
    _publishEvent(startEvent);

    try {
      // 2. Evaluate Decision
      final result = await _service.processRequest(request);

      final compTimeStr = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}';
      _addTimelineEntry('$compTimeStr — ⚡ Decision Complete: ${result.recommendation.name.toUpperCase()} (${(result.emergencyConfidence * 100).toInt()}%)');

      // 3. Emit DecisionCompletedPlatformEvent
      final compEvent = DecisionCompletedPlatformEvent(
        sessionId: request.sessionId,
        recommendation: result.recommendation.name,
        confidence: result.emergencyConfidence,
        processingTimeMs: result.processingTimeMs,
        timestamp: DateTime.now(),
      );
      _publishEvent(compEvent);

      // 4. Emit EmergencyDecisionPlatformEvent (v1)
      final decEvent = EmergencyDecisionPlatformEvent(
        result: result,
        timestamp: DateTime.now(),
      );
      _publishEvent(decEvent);

      // 5. Update State
      state = state.copyWith(
        status: DecisionStatus.completed,
        lastResult: result,
        telemetry: _service.telemetry,
        evidenceTimeline: List.from(_evidenceTimeline),
      );

      appLogger.info(
        'DecisionController: 🧠 Emergency Decision Evaluated: Recommendation=${result.recommendation.name.toUpperCase()}, '
        'Confidence=${(result.emergencyConfidence * 100).toStringAsFixed(1)}%, Latency=${result.processingTimeMs}ms',
      );
    } on DecisionError catch (e) {
      _handleError(e.category, e.message);
    } catch (e) {
      _handleError(DecisionErrorCategory.evaluationFailure, e.toString());
    }
  }

  void _addTimelineEntry(String entry) {
    _evidenceTimeline.add(entry);
    if (_evidenceTimeline.length > 20) {
      _evidenceTimeline.removeAt(0);
    }
  }

  EmergencyDecisionRequest _copyRequestWith(
    EmergencyDecisionRequest existing, {
    String? transcript,
    EmergencyIntentResult? intentResult,
    DateTime? intentTimestamp,
    SpeakerVerificationResult? speakerResult,
    DateTime? speakerTimestamp,
    VocalBiomarkerResult? biomarkerResult,
    DateTime? biomarkerTimestamp,
  }) {
    return EmergencyDecisionRequest(
      sessionId: existing.sessionId,
      transcript: transcript ?? existing.transcript,
      intentResult: intentResult ?? existing.intentResult,
      intentTimestamp: intentTimestamp ?? existing.intentTimestamp,
      speakerResult: speakerResult ?? existing.speakerResult,
      speakerTimestamp: speakerTimestamp ?? existing.speakerTimestamp,
      biomarkerResult: biomarkerResult ?? existing.biomarkerResult,
      biomarkerTimestamp: biomarkerTimestamp ?? existing.biomarkerTimestamp,
      vadConfidence: existing.vadConfidence,
      timestamp: DateTime.now(),
    );
  }

  void _handleError(DecisionErrorCategory category, String message) {
    state = state.copyWith(
      status: DecisionStatus.failed,
      errorCategory: category,
      errorMessage: message,
      telemetry: _service.telemetry,
      evidenceTimeline: List.from(_evidenceTimeline),
    );

    appLogger.error('DecisionController: Evaluation Error [${category.name}]: $message');
  }

  void _publishEvent(PlatformEvent event) {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      bus.publish(event.eventName, event.payload);
    } catch (e) {
      appLogger.warning('DecisionController: Could not publish Decision event to EmergencyEventBus: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _busSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
