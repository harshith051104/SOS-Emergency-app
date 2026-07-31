/// vocal_biomarker_analyzer_test.dart
///
/// Unit tests for FeatureBasedAnalyzer, MockBiomarkerAnalyzer, and VocalBiomarkerService.

library;

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/vocal_biomarkers/domain/entities/vocal_biomarker_request.dart';
import 'package:elly/features/emergency/vocal_biomarkers/domain/entities/vocal_biomarker_config.dart';
import 'package:elly/features/emergency/vocal_biomarkers/domain/entities/vocal_biomarker_error.dart';
import 'package:elly/features/emergency/vocal_biomarkers/data/analyzers/feature_based_analyzer.dart';
import 'package:elly/features/emergency/vocal_biomarkers/data/analyzers/mock_biomarker_analyzer.dart';
import 'package:elly/features/emergency/vocal_biomarkers/data/services/vocal_biomarker_service.dart';

void main() {
  group('VocalBiomarkerAnalyzer Unit Tests', () {
    late FeatureBasedAnalyzer featureAnalyzer;
    late MockBiomarkerAnalyzer mockAnalyzer;

    setUp(() {
      featureAnalyzer = FeatureBasedAnalyzer();
      mockAnalyzer = MockBiomarkerAnalyzer();
    });

    tearDown(() {
      featureAnalyzer.dispose();
      mockAnalyzer.dispose();
    });

    test('MockBiomarkerAnalyzer returns expected mock acoustic features', () async {
      final pcmBytes = Uint8List(16000 * 2 * 1); // 1 sec of audio
      final request = VocalBiomarkerRequest(
        sessionId: 'test_session_1',
        audioBuffer: AudioBuffer(pcmData: pcmBytes),
        timestamp: DateTime.now(),
      );

      final result = await mockAnalyzer.analyze(request);

      expect(result.sessionId, equals('test_session_1'));
      expect(result.processingMethod, equals('MOCK_BIOMARKER_ANALYZER'));
      expect(result.voiceStability, greaterThan(0.0));
      expect(result.vocalTension, greaterThanOrEqualTo(0.0));
      expect(result.pitchVariability, greaterThan(0.0));
      expect(result.jitter, greaterThan(0.0));
      expect(result.shimmer, greaterThan(0.0));
    });

    test('FeatureBasedAnalyzer extracts valid acoustic metrics from synthetic 200Hz sine wave', () async {
      // Generate 1 second of 200 Hz sine wave at 16kHz
      const sampleRate = 16000;
      const durationSec = 1.0;
      final int numSamples = (sampleRate * durationSec).toInt();
      final Int16List pcmData = Int16List(numSamples);

      for (int i = 0; i < numSamples; i++) {
        final double t = i / sampleRate;
        final double sample = 0.5 * 32767 * (2.0 * 3.141592653589793 * 200.0 * t);
        pcmData[i] = sample.clamp(-32768, 32767).toInt();
      }

      final request = VocalBiomarkerRequest(
        sessionId: 'test_sine_wave',
        audioBuffer: AudioBuffer(pcmData: pcmData.buffer.asUint8List()),
        timestamp: DateTime.now(),
      );

      final result = await featureAnalyzer.analyze(request);

      expect(result.sessionId, equals('test_sine_wave'));
      expect(result.processingMethod, equals('FEATURE_BASED_DSP'));
      expect(result.voiceStability, greaterThan(0.0));
      expect(result.voiceStability, lessThanOrEqualTo(1.0));
      expect(result.dspVersion, equals('v1.0.0-dsp'));
      expect(result.algorithmVersion, equals('v1.0.0-acoustic'));
    });

    test('VocalBiomarkerService throws on insufficient audio duration', () async {
      final service = VocalBiomarkerService(
        analyzer: mockAnalyzer,
        config: const VocalBiomarkerConfig(minimumAudioDurationMs: 1000),
      );

      final shortPcm = Uint8List(1600); // ~50ms
      final request = VocalBiomarkerRequest(
        sessionId: 'short_audio',
        audioBuffer: AudioBuffer(pcmData: shortPcm),
        timestamp: DateTime.now(),
      );

      expect(
        () => service.processRequest(request),
        throwsA(isA<VocalBiomarkerError>().having(
          (e) => e.category,
          'category',
          equals(VocalBiomarkerErrorCategory.insufficientAudio),
        )),
      );
    });

    test('VocalBiomarkerService records telemetry on successful analysis', () async {
      final service = VocalBiomarkerService(
        analyzer: mockAnalyzer,
        config: const VocalBiomarkerConfig(minimumAudioDurationMs: 100),
      );

      final pcmBytes = Uint8List(16000 * 2 * 1); // 1 sec
      final request = VocalBiomarkerRequest(
        sessionId: 'telemetry_test',
        audioBuffer: AudioBuffer(pcmData: pcmBytes),
        timestamp: DateTime.now(),
      );

      await service.processRequest(request);

      expect(service.telemetry.analysisCount, equals(1));
      expect(service.telemetry.failureCount, equals(0));
      expect(service.telemetry.averageStability, greaterThan(0.0));
    });
  });
}
