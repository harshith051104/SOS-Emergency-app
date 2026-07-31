/// vocal_biomarker_config.dart
///
/// Configuration parameters and thresholds for Vocal Biomarker Analysis.

library;

import 'package:flutter/foundation.dart';

@immutable
class VocalBiomarkerConfig {
  const VocalBiomarkerConfig({
    this.minimumAudioDurationMs = 500,
    this.supportedSampleRate = 16000,
    this.maxLatencyMs = 250,
  });

  /// Minimum audio duration in milliseconds required for valid feature extraction
  final int minimumAudioDurationMs;

  /// Supported audio sample rate in Hz (16000 Hz / 16kHz)
  final int supportedSampleRate;

  /// Target maximum processing latency in milliseconds
  final int maxLatencyMs;
}
