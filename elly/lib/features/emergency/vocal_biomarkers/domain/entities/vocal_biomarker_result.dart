/// vocal_biomarker_result.dart
///
/// Immutable domain model containing extracted acoustic and signal features.

library;

import 'package:flutter/foundation.dart';

@immutable
class VocalBiomarkerResult {
  const VocalBiomarkerResult({
    required this.sessionId,
    required this.vocalTension,
    required this.speechInstability,
    required this.breathingIrregularity,
    required this.pitchVariability,
    required this.energyVariability,
    required this.jitter,
    required this.shimmer,
    required this.harmonicsToNoiseRatio,
    required this.spectralCentroid,
    required this.voiceStability,
    required this.confidence,
    required this.processingTimeMs,
    required this.processingMethod,
    this.dspVersion = 'v1.0.0-dsp',
    this.algorithmVersion = 'v1.0.0-acoustic',
    required this.timestamp,
  });

  final String sessionId;
  /// Normalized measure of high-frequency energy ratio and micro-tremor (0.0 to 1.0)
  final double vocalTension;
  /// Variance in pitch ($F_0$) & energy continuity over time (0.0 to 1.0)
  final double speechInstability;
  /// Ratio & cadence of unvoiced/gasp/pause frames to voiced frames (0.0 to 1.0)
  final double breathingIrregularity;
  /// Standard deviation of fundamental frequency F0 (Hz)
  final double pitchVariability;
  /// RMS energy variance across frame window (dB / normalized)
  final double energyVariability;
  /// Period-to-period pitch perturbation percentage (%)
  final double jitter;
  /// Period-to-period amplitude perturbation percentage (%)
  final double shimmer;
  /// Ratio of harmonic energy to inharmonic noise (dB)
  final double harmonicsToNoiseRatio;
  /// Center of gravity of frequency spectrum (Hz)
  final double spectralCentroid;
  /// Overall signal stability score (0.0 to 1.0)
  final double voiceStability;
  /// Estimation confidence (0.0 to 1.0)
  final double confidence;
  /// Latency in milliseconds for feature extraction
  final int processingTimeMs;
  /// Processing engine or method used (e.g. 'FEATURE_BASED', 'MOCK')
  final String processingMethod;
  /// DSP version tag
  final String dspVersion;
  /// Algorithm version tag
  final String algorithmVersion;
  /// Timestamp of analysis
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'vocalTension': vocalTension,
        'speechInstability': speechInstability,
        'breathingIrregularity': breathingIrregularity,
        'pitchVariability': pitchVariability,
        'energyVariability': energyVariability,
        'jitter': jitter,
        'shimmer': shimmer,
        'harmonicsToNoiseRatio': harmonicsToNoiseRatio,
        'spectralCentroid': spectralCentroid,
        'voiceStability': voiceStability,
        'confidence': confidence,
        'processingTimeMs': processingTimeMs,
        'processingMethod': processingMethod,
        'dspVersion': dspVersion,
        'algorithmVersion': algorithmVersion,
        'timestamp': timestamp.toIso8601String(),
      };
}
