/// speaker_verification_service.dart
///
/// Application service layer managing timeouts, validation, error classification,
/// and extended telemetry tracking for Speaker Verification.

library;

import 'dart:async';
import 'package:elly/features/emergency/speaker_verification/domain/interfaces/i_speaker_verifier.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_request.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_error.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_telemetry.dart';

class SpeakerVerificationService {
  SpeakerVerificationService({
    required SpeakerVerifier verifier,
    int timeoutMs = 1000,
    int minDurationMs = 500,
  })  : _verifier = verifier,
        _timeoutMs = timeoutMs,
        _minDurationMs = minDurationMs;

  final SpeakerVerifier _verifier;
  final int _timeoutMs;
  final int _minDurationMs;
  SpeakerVerificationTelemetry _telemetry = const SpeakerVerificationTelemetry();

  SpeakerVerificationTelemetry get telemetry => _telemetry;

  Future<SpeakerVerificationResult> processRequest(SpeakerVerificationRequest request) async {
    if (request.audioBuffer.pcmData.isEmpty || request.audioBuffer.durationMs < _minDurationMs) {
      _telemetry = _telemetry.copyWith(failedMatches: _telemetry.failedMatches + 1);
      throw SpeakerVerificationError(
        category: SpeakerVerificationErrorCategory.insufficientAudio,
        message: 'Audio buffer is empty or shorter than min duration (${_minDurationMs}ms).',
        timestamp: DateTime.now(),
      );
    }

    try {
      final result = await _verifier
          .verify(request)
          .timeout(Duration(milliseconds: _timeoutMs), onTimeout: () {
        throw SpeakerVerificationError(
          category: SpeakerVerificationErrorCategory.timeout,
          message: 'Speaker verification timed out after ${_timeoutMs}ms.',
          timestamp: DateTime.now(),
        );
      });

      _updateTelemetry(result);
      return result;
    } catch (e) {
      _telemetry = _telemetry.copyWith(failedMatches: _telemetry.failedMatches + 1);
      rethrow;
    }
  }

  void _updateTelemetry(SpeakerVerificationResult result) {
    final count = _telemetry.verificationCount + 1;
    final succ = result.match ? _telemetry.successfulMatches + 1 : _telemetry.successfulMatches;
    final fail = !result.match ? _telemetry.failedMatches + 1 : _telemetry.failedMatches;

    final avgLatency = ((_telemetry.averageLatencyMs * _telemetry.verificationCount) + result.processingTimeMs) ~/ count;
    final avgConf = ((_telemetry.averageConfidence * _telemetry.verificationCount) + result.confidence) / count;
    final avgSim = ((_telemetry.averageSimilarity * _telemetry.verificationCount) + result.confidence) / count;

    _telemetry = _telemetry.copyWith(
      verificationCount: count,
      successfulMatches: succ,
      failedMatches: fail,
      averageLatencyMs: avgLatency,
      averageConfidence: avgConf,
      averageSimilarity: avgSim,
      falseRejectCount: !result.match && result.confidence >= 0.60 ? _telemetry.falseRejectCount + 1 : _telemetry.falseRejectCount,
      falseAcceptCount: result.match && result.confidence < 0.70 ? _telemetry.falseAcceptCount + 1 : _telemetry.falseAcceptCount,
    );
  }

  void dispose() {
    _verifier.dispose();
  }
}
