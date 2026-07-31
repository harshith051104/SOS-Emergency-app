import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/recognizers/whisper_speech_recognizer.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/recognizers/mock_speech_recognizer.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/speech_session_builder.dart';

void main() {
  group('SpeechRecognizer Unit Tests', () {
    late WhisperSpeechRecognizer whisperRecognizer;
    late MockSpeechRecognizer mockRecognizer;

    setUp(() {
      whisperRecognizer = WhisperSpeechRecognizer(config: const SpeechConfig());
      mockRecognizer = MockSpeechRecognizer(mockText: 'Emergency! Send help!');
    });

    tearDown(() {
      whisperRecognizer.dispose();
      mockRecognizer.dispose();
    });

    test('Empty audio buffer returns empty transcript', () async {
      final session = SpeechSessionBuilder.buildSession(
        pcmData: Uint8List(0),
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
      );

      final result = await mockRecognizer.transcribe(session);

      expect(result.text, isEmpty);
      expect(result.confidence, equals(0.0));
    });

    test('Non-empty audio buffer returns valid transcription result', () async {
      final pcmBytes = Uint8List(16000 * 2); // 1 second 16kHz PCM
      final session = SpeechSessionBuilder.buildSession(
        pcmData: pcmBytes,
        startedAt: DateTime.now().subtract(const Duration(seconds: 1)),
        endedAt: DateTime.now(),
      );

      final result = await mockRecognizer.transcribe(session);

      expect(result.text, equals('Emergency! Send help!'));
      expect(result.confidence, equals(0.95));
      expect(result.engine, equals(SpeechEngine.mock));
    });

    test('Cancellation returns cancelled transcript tag', () async {
      final pcmBytes = Uint8List(16000 * 2);
      final session = SpeechSessionBuilder.buildSession(
        pcmData: pcmBytes,
        startedAt: DateTime.now().subtract(const Duration(seconds: 1)),
        endedAt: DateTime.now(),
      );

      await mockRecognizer.cancelCurrentRecognition();
      final result = await mockRecognizer.transcribe(session);

      expect(result.text, equals('[CANCELLED]'));
    });
  });
}
