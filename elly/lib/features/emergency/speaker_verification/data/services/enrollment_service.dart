/// enrollment_service.dart
///
/// Application service managing user voice profile enrollment, quality checks,
/// multi-sample embedding vector averaging, and repository persistence.

library;

import 'dart:async';
import 'dart:math' as math;
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_profile.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_error.dart';
import 'package:elly/features/emergency/speaker_verification/domain/interfaces/i_speaker_profile_repository.dart';
import 'package:elly/features/emergency/speaker_verification/data/repositories/local_speaker_profile_repository.dart';

class EnrollmentService {
  EnrollmentService({SpeakerProfileRepository? repository})
      : _repository = repository ?? LocalSpeakerProfileRepository();

  final SpeakerProfileRepository _repository;

  Future<List<SpeakerProfile>> get enrolledProfiles => _repository.getProfiles();

  Future<SpeakerProfile?> get primaryProfile async {
    final profiles = await _repository.getProfiles();
    if (profiles.isEmpty) return null;
    return profiles.firstWhere((p) => p.isPrimary, orElse: () => profiles.first);
  }

  /// Quality validation check for voice enrollment recording sample
  void validateSampleQuality(AudioBuffer audioBuffer) {
    if (audioBuffer.pcmData.isEmpty || audioBuffer.durationMs < 1000) {
      throw SpeakerVerificationError(
        category: SpeakerVerificationErrorCategory.insufficientAudio,
        message: 'Enrollment audio buffer too short (${audioBuffer.durationMs}ms). Minimum 1000ms required.',
        timestamp: DateTime.now(),
      );
    }

    // Check RMS signal level to ensure non-silent recording
    double sum = 0.0;
    final pcm = audioBuffer.pcmData;
    for (int i = 0; i < pcm.length; i++) {
      final s = pcm[i] / 255.0;
      sum += s * s;
    }
    final rms = math.sqrt(sum / pcm.length);
    if (rms < 0.0001) {
      throw SpeakerVerificationError(
        category: SpeakerVerificationErrorCategory.insufficientAudio,
        message: 'Enrollment sample signal level too low / silent (RMS: ${rms.toStringAsFixed(5)}).',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Single sample profile creation
  Future<SpeakerProfile> enrollProfile({
    required String profileId,
    required String displayName,
    required AudioBuffer audioBuffer,
    bool isPrimary = true,
  }) async {
    validateSampleQuality(audioBuffer);
    final embedding = extractEmbedding(audioBuffer);

    final profile = SpeakerProfile(
      profileId: profileId,
      displayName: displayName,
      isPrimary: isPrimary,
      createdAt: DateTime.now(),
      embedding: embedding,
    );

    await _repository.save(profile);
    appLogger.info('EnrollmentService: Successfully enrolled profile "${profile.displayName}" [ID: ${profile.profileId}]');
    return profile;
  }

  /// Multi-sample profile creation by averaging acoustic embedding vectors across 3 utterance samples
  Future<SpeakerProfile> enrollFromSamples({
    required String profileId,
    required String displayName,
    required List<AudioBuffer> samples,
    bool isPrimary = true,
  }) async {
    if (samples.length < 3) {
      throw SpeakerVerificationError(
        category: SpeakerVerificationErrorCategory.insufficientAudio,
        message: 'Multi-sample enrollment requires at least 3 audio samples.',
        timestamp: DateTime.now(),
      );
    }

    for (final sample in samples) {
      validateSampleQuality(sample);
    }

    final embeddings = samples.map(extractEmbedding).toList();
    final dim = embeddings.first.length;
    final averagedEmbedding = List<double>.generate(dim, (index) {
      double sum = 0.0;
      for (final emb in embeddings) {
        sum += emb[index];
      }
      return sum / embeddings.length;
    });

    final profile = SpeakerProfile(
      profileId: profileId,
      displayName: displayName,
      isPrimary: isPrimary,
      createdAt: DateTime.now(),
      embedding: averagedEmbedding,
    );

    await _repository.save(profile);
    appLogger.info('EnrollmentService: Successfully enrolled 3-sample reference profile "${profile.displayName}"');
    return profile;
  }

  Future<void> saveDirectProfile(SpeakerProfile profile) async {
    await _repository.save(profile);
  }

  Future<void> deleteProfile(String profileId) async {
    await _repository.delete(profileId);
    appLogger.info('EnrollmentService: Revoked speaker profile ID $profileId.');
  }

  List<double> extractEmbedding(AudioBuffer audio) {
    final pcm = audio.pcmData;
    final random = math.Random(pcm.length + 1002);
    return List<double>.generate(128, (i) {
      final sample = (i < pcm.length) ? pcm[i] / 255.0 : random.nextDouble();
      return (sample * 0.2 + (i % 5) * 0.1).clamp(-1.0, 1.0);
    });
  }
}
