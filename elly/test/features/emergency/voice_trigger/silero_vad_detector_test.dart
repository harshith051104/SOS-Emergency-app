import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/voice_trigger/domain/interfaces/i_voice_activity_detector.dart';
import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_config.dart';
import 'package:elly/features/emergency/voice_trigger/data/services/silero_vad_detector.dart';

void main() {
  group('SileroVadDetector Unit Tests', () {
    late SileroVadDetector detector;

    setUp(() {
      detector = SileroVadDetector(config: const VadConfig());
    });

    tearDown(() {
      detector.dispose();
    });

    test('Silence PCM frame (all zeros) returns isSpeech = false', () async {
      final silencePcm = Uint8List(1024); // 512 samples @ 16-bit PCM = 0
      final frame = AudioFrame(pcmData: silencePcm);

      final result = await detector.analyze(frame);

      expect(result.isSpeech, isFalse);
      expect(result.speechProbability, equals(0.0));
    });

    test('High energy PCM frame (simulated speech) returns isSpeech = true', () async {
      // Simulate high amplitude 16-bit PCM sine wave
      final pcmBytes = Uint8List(1024);
      final byteData = ByteData.sublistView(pcmBytes);
      for (var i = 0; i < 512; i++) {
        // High amplitude wave sample (~ 15000)
        final val = (15000 * (i % 2 == 0 ? 1 : -1));
        byteData.setInt16(i * 2, val, Endian.little);
      }

      final frame = AudioFrame(pcmData: pcmBytes);
      final result = await detector.analyze(frame);

      expect(result.isSpeech, isTrue);
      expect(result.speechProbability, greaterThanOrEqualTo(0.5));
    });

    test('Custom threshold configuration is respected', () async {
      final strictDetector = SileroVadDetector(
        config: const VadConfig(speechThreshold: 0.95),
      );

      final moderatePcm = Uint8List(1024);
      final byteData = ByteData.sublistView(moderatePcm);
      for (var i = 0; i < 512; i++) {
        final val = (3000 * (i % 2 == 0 ? 1 : -1));
        byteData.setInt16(i * 2, val, Endian.little);
      }

      final frame = AudioFrame(pcmData: moderatePcm);
      final result = await strictDetector.analyze(frame);

      expect(result.isSpeech, isFalse);
      strictDetector.dispose();
    });
  });
}
