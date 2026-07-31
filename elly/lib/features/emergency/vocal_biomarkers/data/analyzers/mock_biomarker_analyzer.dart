/// mock_biomarker_analyzer.dart
///
/// Mock implementation of VocalBiomarkerAnalyzer for unit testing and instant UI simulation.

library;

import '../../domain/entities/vocal_biomarker_request.dart';
import '../../domain/entities/vocal_biomarker_result.dart';
import '../../domain/interfaces/i_vocal_biomarker_analyzer.dart';

class MockBiomarkerAnalyzer implements VocalBiomarkerAnalyzer {
  MockBiomarkerAnalyzer({
    this.mockResult,
    this.simulatedLatencyMs = 3,
  });

  final VocalBiomarkerResult? mockResult;
  final int simulatedLatencyMs;

  @override
  Future<VocalBiomarkerResult> analyze(VocalBiomarkerRequest request) async {
    if (simulatedLatencyMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: simulatedLatencyMs));
    }

    if (mockResult != null) {
      return mockResult!;
    }

    return VocalBiomarkerResult(
      sessionId: request.sessionId,
      vocalTension: 0.28,
      speechInstability: 0.24,
      breathingIrregularity: 0.15,
      pitchVariability: 14.5, // 14.5 Hz
      energyVariability: 0.35,
      jitter: 1.2, // 1.2%
      shimmer: 2.8, // 2.8%
      harmonicsToNoiseRatio: 22.4, // 22.4 dB
      spectralCentroid: 1450.0, // 1450 Hz
      voiceStability: 0.88,
      confidence: 0.94,
      processingTimeMs: simulatedLatencyMs,
      processingMethod: 'MOCK_BIOMARKER_ANALYZER',
      dspVersion: 'v1.0.0-mock',
      algorithmVersion: 'v1.0.0-mock',
      timestamp: DateTime.now(),
    );
  }

  @override
  void dispose() {}
}
