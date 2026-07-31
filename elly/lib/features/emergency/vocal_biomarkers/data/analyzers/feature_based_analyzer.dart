/// feature_based_analyzer.dart
///
/// Pure Dart 100% offline Digital Signal Processing (DSP) and acoustic feature extraction engine.
/// Computes pitch ($F_0$), jitter, shimmer, HNR, spectral centroid, vocal tension, 
/// speech instability, and breathing irregularity from 16kHz 16-bit PCM mono audio.

library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../../domain/entities/vocal_biomarker_request.dart';
import '../../domain/entities/vocal_biomarker_result.dart';
import '../../domain/interfaces/i_vocal_biomarker_analyzer.dart';

class FeatureBasedAnalyzer implements VocalBiomarkerAnalyzer {
  static const String dspVersionConst = 'v1.0.0-dsp';
  static const String algorithmVersionConst = 'v1.0.0-acoustic';

  @override
  Future<VocalBiomarkerResult> analyze(VocalBiomarkerRequest request) async {
    final stopwatch = Stopwatch()..start();
    final pcmBytes = request.audioBuffer.pcmData;

    // Convert byte array (16-bit LE PCM) to double samples [-1.0, 1.0]
    final sampleCount = pcmBytes.length ~/ 2;
    if (sampleCount < 160) {
      // Extremely short buffer fallback
      return _buildFallbackResult(request.sessionId, stopwatch.elapsedMilliseconds);
    }

    final Int16List int16Data = pcmBytes.buffer.asInt16List(pcmBytes.offsetInBytes, sampleCount);
    final List<double> samples = List<double>.filled(sampleCount, 0.0);
    for (int i = 0; i < sampleCount; i++) {
      samples[i] = int16Data[i] / 32768.0;
    }

    final int sampleRate = request.sampleRate > 0 ? request.sampleRate : 16000;
    final int frameSize = (sampleRate * 0.020).round(); // 20ms frame = 320 samples
    final int hopSize = (sampleRate * 0.010).round();   // 10ms hop = 160 samples

    if (sampleCount < frameSize) {
      return _buildFallbackResult(request.sessionId, stopwatch.elapsedMilliseconds);
    }

    final int numFrames = (sampleCount - frameSize) ~/ hopSize + 1;
    final List<double> frameEnergies = [];
    final List<double> framePitchPeriods = []; // In seconds
    final List<double> framePitchFreqs = [];   // In Hz
    final List<double> framePeakAmplitudes = [];
    final List<double> frameZcr = [];
    final List<double> frameHnr = [];
    int unvoicedOrSilentFrames = 0;

    // Min and Max lag for pitch detection (50Hz to 400Hz)
    final int minLag = (sampleRate / 400).floor(); // ~40 at 16kHz
    final int maxLag = (sampleRate / 50).ceil();   // ~320 at 16kHz

    for (int f = 0; f < numFrames; f++) {
      final int start = f * hopSize;
      double energy = 0.0;
      double peakAmp = 0.0;
      int zeroCrossings = 0;

      for (int i = 0; i < frameSize; i++) {
        final double val = samples[start + i];
        energy += val * val;
        final double absVal = val.abs();
        if (absVal > peakAmp) peakAmp = absVal;

        if (i > 0) {
          final double prevVal = samples[start + i - 1];
          if ((val >= 0 && prevVal < 0) || (val < 0 && prevVal >= 0)) {
            zeroCrossings++;
          }
        }
      }

      final double rms = math.sqrt(energy / frameSize);
      frameEnergies.add(rms);
      framePeakAmplitudes.add(peakAmp);
      frameZcr.add(zeroCrossings / frameSize);

      // Silence or unvoiced threshold
      if (rms < 0.015) {
        unvoicedOrSilentFrames++;
        continue;
      }

      // Autocorrelation for pitch and HNR estimation
      double maxAutocorr = -1.0;
      int bestLag = 0;
      double r0 = 0.0; // r(0) for normalization

      for (int i = 0; i < frameSize; i++) {
        r0 += samples[start + i] * samples[start + i];
      }

      if (r0 > 1e-6) {
        for (int lag = minLag; lag <= maxLag && (start + frameSize + lag) <= sampleCount; lag++) {
          double autocorr = 0.0;
          for (int i = 0; i < frameSize; i++) {
            autocorr += samples[start + i] * samples[start + i + lag];
          }
          if (autocorr > maxAutocorr) {
            maxAutocorr = autocorr;
            bestLag = lag;
          }
        }

        final double normAutocorr = maxAutocorr / r0;
        if (normAutocorr > 0.3 && bestLag > 0) {
          final double periodSec = bestLag / sampleRate;
          final double freqHz = sampleRate / bestLag;
          framePitchPeriods.add(periodSec);
          framePitchFreqs.add(freqHz);

          // HNR = 10 * log10( r(tau) / (r(0) - r(tau)) )
          final double hnrVal = (r0 - maxAutocorr) > 1e-6
              ? 10.0 * (math.log(maxAutocorr / (r0 - maxAutocorr)) / math.ln10)
              : 25.0;
          frameHnr.add(hnrVal.clamp(0.0, 35.0));
        } else {
          unvoicedOrSilentFrames++;
        }
      } else {
        unvoicedOrSilentFrames++;
      }
    }

    // --- Feature Aggregations ---

    // 1. Pitch & Pitch Variability
    double pitchMean = 0.0;
    double pitchVariability = 0.0;
    if (framePitchFreqs.isNotEmpty) {
      pitchMean = framePitchFreqs.reduce((a, b) => a + b) / framePitchFreqs.length;
      final double variance = framePitchFreqs
              .map((f) => (f - pitchMean) * (f - pitchMean))
              .reduce((a, b) => a + b) /
          framePitchFreqs.length;
      pitchVariability = math.sqrt(variance);
    }

    // 2. Jitter (%) -> Period-to-period pitch perturbation
    double jitterPercent = 0.0;
    if (framePitchPeriods.length >= 2) {
      double totalPeriodDiff = 0.0;
      final double meanPeriod = framePitchPeriods.reduce((a, b) => a + b) / framePitchPeriods.length;
      for (int i = 0; i < framePitchPeriods.length - 1; i++) {
        totalPeriodDiff += (framePitchPeriods[i] - framePitchPeriods[i + 1]).abs();
      }
      final double avgPeriodDiff = totalPeriodDiff / (framePitchPeriods.length - 1);
      if (meanPeriod > 0) {
        jitterPercent = (avgPeriodDiff / meanPeriod) * 100.0;
      }
    }

    // 3. Shimmer (%) -> Peak-to-peak amplitude perturbation
    double shimmerPercent = 0.0;
    if (framePeakAmplitudes.length >= 2) {
      double totalAmpDiff = 0.0;
      final double meanAmp = framePeakAmplitudes.reduce((a, b) => a + b) / framePeakAmplitudes.length;
      for (int i = 0; i < framePeakAmplitudes.length - 1; i++) {
        totalAmpDiff += (framePeakAmplitudes[i] - framePeakAmplitudes[i + 1]).abs();
      }
      final double avgAmpDiff = totalAmpDiff / (framePeakAmplitudes.length - 1);
      if (meanAmp > 0) {
        shimmerPercent = (avgAmpDiff / meanAmp) * 100.0;
      }
    }

    // 4. Harmonics-to-Noise Ratio (HNR in dB)
    double meanHnr = 15.0; // Default baseline
    if (frameHnr.isNotEmpty) {
      meanHnr = frameHnr.reduce((a, b) => a + b) / frameHnr.length;
    }

    // 5. Energy Variability (dB)
    double energyVar = 0.0;
    if (frameEnergies.isNotEmpty) {
      final double meanEnergy = frameEnergies.reduce((a, b) => a + b) / frameEnergies.length;
      final double eVariance = frameEnergies
              .map((e) => (e - meanEnergy) * (e - meanEnergy))
              .reduce((a, b) => a + b) /
          frameEnergies.length;
      energyVar = math.sqrt(eVariance);
    }

    // 6. Spectral Centroid (Hz approximation via ZCR & Sample Rate)
    final double meanZcr = frameZcr.isNotEmpty ? (frameZcr.reduce((a, b) => a + b) / frameZcr.length) : 0.1;
    final double spectralCentroidHz = meanZcr * (sampleRate / 2.0);

    // 7. Breathing / Pause Irregularity (0.0 to 1.0)
    double breathingIrregularity = unvoicedOrSilentFrames / (numFrames > 0 ? numFrames : 1);
    breathingIrregularity = breathingIrregularity.clamp(0.0, 1.0);

    // 8. Vocal Tension (0.0 to 1.0)
    // High tension correlates with low HNR, high jitter, and high spectral centroid (>1500Hz)
    final double hnrTensionComponent = ((25.0 - meanHnr) / 25.0).clamp(0.0, 1.0);
    final double jitterTensionComponent = (jitterPercent / 5.0).clamp(0.0, 1.0);
    final double scTensionComponent = ((spectralCentroidHz - 1000) / 2000.0).clamp(0.0, 1.0);
    final double vocalTension = (hnrTensionComponent * 0.4 + jitterTensionComponent * 0.4 + scTensionComponent * 0.2).clamp(0.0, 1.0);

    // 9. Speech Instability (0.0 to 1.0)
    // High instability = high pitch variability, high shimmer, and high energy variance
    final double pitchInstabilityComponent = (pitchVariability / 50.0).clamp(0.0, 1.0);
    final double shimmerInstabilityComponent = (shimmerPercent / 10.0).clamp(0.0, 1.0);
    final double energyInstabilityComponent = (energyVar * 10.0).clamp(0.0, 1.0);
    final double speechInstability = (pitchInstabilityComponent * 0.4 + shimmerInstabilityComponent * 0.4 + energyInstabilityComponent * 0.2).clamp(0.0, 1.0);

    // 10. Voice Stability (0.0 to 1.0)
    final double voiceStability = (1.0 - (vocalTension * 0.5 + speechInstability * 0.5)).clamp(0.0, 1.0);

    // 11. Confidence (0.0 to 1.0)
    final double confidence = (framePitchFreqs.length / (numFrames > 0 ? numFrames : 1)).clamp(0.4, 0.98);

    stopwatch.stop();

    return VocalBiomarkerResult(
      sessionId: request.sessionId,
      vocalTension: _round(vocalTension),
      speechInstability: _round(speechInstability),
      breathingIrregularity: _round(breathingIrregularity),
      pitchVariability: _round(pitchVariability),
      energyVariability: _round(energyVar),
      jitter: _round(jitterPercent),
      shimmer: _round(shimmerPercent),
      harmonicsToNoiseRatio: _round(meanHnr),
      spectralCentroid: _round(spectralCentroidHz),
      voiceStability: _round(voiceStability),
      confidence: _round(confidence),
      processingTimeMs: stopwatch.elapsedMilliseconds,
      processingMethod: 'FEATURE_BASED_DSP',
      timestamp: DateTime.now(),
    );
  }

  VocalBiomarkerResult _buildFallbackResult(String sessionId, int elapsedMs) {
    return VocalBiomarkerResult(
      sessionId: sessionId,
      vocalTension: 0.1,
      speechInstability: 0.1,
      breathingIrregularity: 0.1,
      pitchVariability: 0.0,
      energyVariability: 0.0,
      jitter: 0.5,
      shimmer: 1.0,
      harmonicsToNoiseRatio: 20.0,
      spectralCentroid: 1200.0,
      voiceStability: 0.9,
      confidence: 0.5,
      processingTimeMs: elapsedMs,
      processingMethod: 'FEATURE_BASED_DSP_FALLBACK',
      timestamp: DateTime.now(),
    );
  }

  double _round(double value) => (value * 1000).round() / 1000.0;

  @override
  void dispose() {}
}
