/// i_speaker_profile_repository.dart
///
/// Abstract repository interface for local encrypted persistence of enrolled speaker profiles.

library;

import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_profile.dart';

abstract class SpeakerProfileRepository {
  Future<void> save(SpeakerProfile profile);
  Future<List<SpeakerProfile>> getProfiles();
  Future<SpeakerProfile?> getProfileById(String profileId);
  Future<void> delete(String profileId);
}
