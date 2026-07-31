/// vocal_biomarker_service.dart
///
/// Application service layer for Vocal Biomarker Analysis. Handles request validation,
/// timeout enforcement, telemetry aggregation, and error translation.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/vocal_biomarker_config.dart';
import '../../domain/entities/vocal_biomarker_error.dart';
import '../../domain/entities/vocal_biomarker_request.dart';
import '../../domain/entities/vocal_biomarker_result.dart';
import '../../domain/entities/vocal_biomarker_telemetry.dart';
import '../../domain/interfaces/i_vocal_biomarker_analyzer.dart';

class VocalBiomarkerService {
  VocalBiomarkerService({
    required VocalBiomarkerAnalyzer analyzer,
    VocalBiomarkerConfig config = const VocalBiomarkerConfig(),
  })  : _analyzer = analyzer,
        _config = config;

  final VocalBiomarkerAnalyzer _analyzer;
  final VocalBiomarkerConfig _config;

  VocalBiomarkerTelemetry _telemetry = const VocalBiomarkerTelemetry();
  VocalBiomarkerTelemetry get telemetry => _telemetry;

  Future<VocalBiomarkerResult> processRequest(VocalBiomarkerRequest request) async {
    // 1. Validate Audio Length & Format
    if (request.audioBuffer.pcmData.isEmpty) {
      _telemetry = _telemetry.recordFailure();
      throw const VocalBiomarkerError(
        VocalBiomarkerErrorCategory.insufficientAudio,
        'Audio buffer is empty.',
      );
    }

    if (request.durationMs < _config.minimumAudioDurationMs) {
      _telemetry = _telemetry.recordFailure();
      throw VocalBiomarkerError(
        VocalBiomarkerErrorCategory.insufficientAudio,
        'Audio duration (${request.durationMs}ms) is less than required minimum (${_config.minimumAudioDurationMs}ms).',
      );
    }

    try {
      // 2. Process with Timeout
      final result = await _analyzer
          .analyze(request)
          .timeout(Duration(milliseconds: _config.maxLatencyMs + 500), onTimeout: () {
        throw const VocalBiomarkerError(
          VocalBiomarkerErrorCategory.timeout,
          'Vocal biomarker analysis exceeded maximum allowable latency timeout.',
        );
      });

      // 3. Update Telemetry
      _telemetry = _telemetry.recordSuccess(
        latencyMs: result.processingTimeMs.toDouble(),
        stability: result.voiceStability,
        confidence: result.confidence,
      );

      return result;
    } on VocalBiomarkerError {
      rethrow;
    } catch (e, stack) {
      _telemetry = _telemetry.recordFailure();
      appLogger.error('VocalBiomarkerService: Unhandled exception during feature extraction: $e\n$stack');
      throw VocalBiomarkerError(
        VocalBiomarkerErrorCategory.featureExtractionFailure,
        'Failed to extract vocal biomarkers: $e',
      );
    }
  }

  void dispose() {
    _analyzer.dispose();
  }
}
