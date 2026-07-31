import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_config.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_request.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';
import 'package:elly/features/emergency/speaker_verification/data/services/enrollment_service.dart';
import 'package:elly/features/emergency/speaker_verification/data/services/verifiers/embedding_speaker_verifier.dart';
import 'package:elly/features/emergency/speaker_verification/data/services/verifiers/mock_speaker_verifier.dart';

void main() {
  group('SpeakerVerifier Engine Unit Tests', () {
    late EnrollmentService enrollmentService;
    late EmbeddingSpeakerVerifier embeddingVerifier;
    late MockSpeakerVerifier mockVerifier;

    Uint8List makeNonSilentPcm(int bytesLength) {
      final pcm = Uint8List(bytesLength);
      for (int i = 0; i < bytesLength; i++) {
        pcm[i] = (i % 250) + 1;
      }
      return pcm;
    }

    setUp(() {
      enrollmentService = EnrollmentService();
      embeddingVerifier = EmbeddingSpeakerVerifier(
        config: const SpeakerVerificationConfig(),
        enrollmentService: enrollmentService,
      );
      mockVerifier = MockSpeakerVerifier(forcedConfidence: 0.95);
    });

    tearDown(() {
      embeddingVerifier.dispose();
      mockVerifier.dispose();
    });

    SpeakerVerificationRequest makeRequest(Uint8List pcm) {
      return SpeakerVerificationRequest(
        sessionId: 'sess_spk_test',
        audioBuffer: AudioBuffer(pcmData: pcm),
        timestamp: DateTime.now(),
      );
    }

    test('Empty audio buffer returns match false with zero confidence', () async {
      final req = makeRequest(Uint8List(0));
      final res = await embeddingVerifier.verify(req);

      expect(res.match, isFalse);
      expect(res.confidence, equals(0.0));
    });

    test('Valid PCM16 audio request matches enrolled speaker profile', () async {
      final pcm = makeNonSilentPcm(16000 * 2);
      await enrollmentService.enrollProfile(
        profileId: 'owner_primary',
        displayName: 'Primary Owner',
        audioBuffer: AudioBuffer(pcmData: pcm),
      );

      final req = makeRequest(pcm);
      final res = await embeddingVerifier.verify(req);

      expect(res.match, isTrue);
      expect(res.confidence, greaterThanOrEqualTo(0.75));
      expect(res.processingMethod, equals(SpeakerVerificationMethod.embedding));
    });

    test('MockSpeakerVerifier returns forced verification results', () async {
      final req = makeRequest(makeNonSilentPcm(16000 * 2));
      final res = await mockVerifier.verify(req);

      expect(res.match, isTrue);
      expect(res.confidence, equals(0.95));
      expect(res.processingMethod, equals(SpeakerVerificationMethod.mock));
    });
  });
}
