/// vocal_biomarker_events.dart
///
/// Schema-versioned (v1) PlatformEvent definitions for Vocal Biomarker Analysis.

library;

import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'vocal_biomarker_result.dart';

class VocalBiomarkerStartedPlatformEvent extends PlatformEvent {
  VocalBiomarkerStartedPlatformEvent({
    required String sessionId,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_bio_start_${timestamp.millisecondsSinceEpoch}',
          eventName: 'VocalBiomarkerStarted',
          payload: {
            'sessionId': sessionId,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class VocalBiomarkerCompletedPlatformEvent extends PlatformEvent {
  VocalBiomarkerCompletedPlatformEvent({
    required String sessionId,
    required String processingMethod,
    required String dspVersion,
    required String algorithmVersion,
    required int processingTimeMs,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_bio_comp_${timestamp.millisecondsSinceEpoch}',
          eventName: 'VocalBiomarkerCompleted',
          payload: {
            'sessionId': sessionId,
            'processingMethod': processingMethod,
            'dspVersion': dspVersion,
            'algorithmVersion': algorithmVersion,
            'processingTimeMs': processingTimeMs,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class VocalBiomarkerAnalyzedPlatformEvent extends PlatformEvent {
  VocalBiomarkerAnalyzedPlatformEvent({
    required VocalBiomarkerResult result,
    required super.timestamp,
    int schemaVersion = 1,
  }) : super(
          eventId: 'evt_bio_analyzed_${timestamp.millisecondsSinceEpoch}',
          eventName: 'VocalBiomarkerAnalyzed',
          payload: {
            'sessionId': result.sessionId,
            'vocalTension': result.vocalTension,
            'speechInstability': result.speechInstability,
            'breathingIrregularity': result.breathingIrregularity,
            'pitchVariability': result.pitchVariability,
            'energyVariability': result.energyVariability,
            'jitter': result.jitter,
            'shimmer': result.shimmer,
            'harmonicsToNoiseRatio': result.harmonicsToNoiseRatio,
            'spectralCentroid': result.spectralCentroid,
            'voiceStability': result.voiceStability,
            'confidence': result.confidence,
            'processingTimeMs': result.processingTimeMs,
            'processingMethod': result.processingMethod,
            'dspVersion': result.dspVersion,
            'algorithmVersion': result.algorithmVersion,
            'schemaVersion': schemaVersion,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}
