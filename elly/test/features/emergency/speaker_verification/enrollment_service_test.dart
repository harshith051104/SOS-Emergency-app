import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_error.dart';
import 'package:elly/features/emergency/speaker_verification/data/services/enrollment_service.dart';

void main() {
  group('EnrollmentService Unit Tests', () {
    late EnrollmentService enrollmentService;

    Uint8List makeNonSilentPcm(int bytesLength) {
      final pcm = Uint8List(bytesLength);
      for (int i = 0; i < bytesLength; i++) {
        pcm[i] = (i % 250) + 1; // Non-zero audio signal
      }
      return pcm;
    }

    setUp(() {
      enrollmentService = EnrollmentService();
    });

    test('Short audio buffer throws insufficientAudio error', () async {
      final shortAudio = AudioBuffer(pcmData: Uint8List(100));

      expect(
        () => enrollmentService.enrollProfile(
          profileId: 'test_user',
          displayName: 'Test User',
          audioBuffer: shortAudio,
        ),
        throwsA(isA<SpeakerVerificationError>().having(
          (e) => e.category,
          'category',
          equals(SpeakerVerificationErrorCategory.insufficientAudio),
        )),
      );
    });

    test('Valid PCM16 audio buffer creates enrolled profile', () async {
      final validAudio = AudioBuffer(pcmData: makeNonSilentPcm(16000 * 2));

      final profile = await enrollmentService.enrollProfile(
        profileId: 'primary_owner',
        displayName: 'Device Owner',
        audioBuffer: validAudio,
      );

      expect(profile.profileId, equals('primary_owner'));
      expect(profile.displayName, equals('Device Owner'));
      expect(profile.isPrimary, isTrue);
      expect(profile.embedding.isNotEmpty, isTrue);
    });

    test('enrollFromSamples averages 3 utterance recordings into reference profile', () async {
      final samples = [
        AudioBuffer(pcmData: makeNonSilentPcm(16000 * 2)),
        AudioBuffer(pcmData: makeNonSilentPcm(16000 * 2)),
        AudioBuffer(pcmData: makeNonSilentPcm(16000 * 2)),
      ];

      final profile = await enrollmentService.enrollFromSamples(
        profileId: 'multi_sample_owner',
        displayName: 'Multi Sample Owner',
        samples: samples,
      );

      expect(profile.profileId, equals('multi_sample_owner'));
      expect(profile.embedding.length, equals(128));
      final profiles = await enrollmentService.enrolledProfiles;
      expect(profiles.length, equals(1));
    });

    test('Revoking profile deletes entry from storage', () async {
      final validAudio = AudioBuffer(pcmData: makeNonSilentPcm(16000 * 2));
      await enrollmentService.enrollProfile(
        profileId: 'revoked_user',
        displayName: 'Revoked User',
        audioBuffer: validAudio,
      );

      await enrollmentService.deleteProfile('revoked_user');
      final profiles = await enrollmentService.enrolledProfiles;
      expect(profiles.where((p) => p.profileId == 'revoked_user'), isEmpty);
    });
  });
}
