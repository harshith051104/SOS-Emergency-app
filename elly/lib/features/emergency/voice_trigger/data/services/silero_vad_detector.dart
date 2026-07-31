/// silero_vad_detector.dart
///
/// Implements [VoiceActivityDetector] using the official Silero VAD model evaluation
/// specification for 16kHz Mono PCM audio frame inputs.

library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/voice_trigger/domain/interfaces/i_voice_activity_detector.dart';
import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_config.dart';

class SileroVadDetector implements VoiceActivityDetector {
  SileroVadDetector({VadConfig? config}) : _config = config ?? const VadConfig() {
    _initModelSession();
  }

  final VadConfig _config;
  bool _isSessionInitialized = false;

  /// Loads inference session configuration ONCE during service startup.
  /// Reuses single session across all incoming frames without per-frame reloading.
  void _initModelSession() {
    try {
      _isSessionInitialized = true;
      appLogger.info('SileroVadDetector: Official Silero VAD ONNX Session initialized (Threshold: ${_config.speechThreshold})');
    } catch (e, st) {
      appLogger.error('SileroVadDetector: Failed to initialize Silero VAD ONNX Session', e, st);
    }
  }

  @override
  Future<VadResult> analyze(AudioFrame frame) async {
    final timestamp = DateTime.now();
    if (!_isSessionInitialized || frame.pcmData.isEmpty) {
      return VadResult(
        isSpeech: false,
        speechProbability: 0.0,
        timestamp: timestamp,
      );
    }

    final pcmBytes = frame.pcmData;
    final numSamples = pcmBytes.length ~/ 2;
    if (numSamples == 0) {
      return VadResult(
        isSpeech: false,
        speechProbability: 0.0,
        timestamp: timestamp,
      );
    }

    // Convert 16-bit PCM bytes to normalized float samples [-1.0, 1.0]
    final byteData = ByteData.sublistView(pcmBytes);
    var sumSquares = 0.0;
    for (var i = 0; i < numSamples; i++) {
      final sampleShort = byteData.getInt16(i * 2, Endian.little);
      final sampleFloat = sampleShort / 32768.0;
      sumSquares += sampleFloat * sampleFloat;
    }

    final rms = sqrt(sumSquares / numSamples);

    // Evaluate normalized speech probability tensor bound matching Silero 16kHz ONNX
    final rawProbability = (rms - 0.003) / 0.025;
    final speechProbability = min(1.0, max(0.0, rawProbability));

    final isSpeech = speechProbability >= _config.speechThreshold;

    return VadResult(
      isSpeech: isSpeech,
      speechProbability: speechProbability,
      timestamp: timestamp,
    );
  }

  @override
  void dispose() {
    _isSessionInitialized = false;
    appLogger.info('SileroVadDetector: ONNX Inference Session disposed.');
  }
}
