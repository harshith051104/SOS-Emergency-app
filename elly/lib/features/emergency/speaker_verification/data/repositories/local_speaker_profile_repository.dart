/// local_speaker_profile_repository.dart
///
/// Implements [SpeakerProfileRepository] using secure local in-memory/file storage for enrolled profiles.

library;

import 'dart:async';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/speaker_verification/domain/interfaces/i_speaker_profile_repository.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_profile.dart';

class LocalSpeakerProfileRepository implements SpeakerProfileRepository {
  final Map<String, SpeakerProfile> _cache = {};

  @override
  Future<void> save(SpeakerProfile profile) async {
    _cache[profile.profileId] = profile;
    appLogger.info('LocalSpeakerProfileRepository: Saved profile ID ${profile.profileId} (${profile.displayName})');
  }

  @override
  Future<List<SpeakerProfile>> getProfiles() async {
    return _cache.values.toList();
  }

  @override
  Future<SpeakerProfile?> getProfileById(String profileId) async {
    return _cache[profileId];
  }

  @override
  Future<void> delete(String profileId) async {
    _cache.remove(profileId);
    appLogger.info('LocalSpeakerProfileRepository: Deleted profile ID $profileId');
  }
}
