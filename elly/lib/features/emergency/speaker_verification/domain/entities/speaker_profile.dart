/// speaker_profile.dart
///
/// Immutable domain model representing an enrolled speaker profile and stored embedding vector.

library;

import 'package:flutter/foundation.dart';

@immutable
class SpeakerProfile {
  const SpeakerProfile({
    required this.profileId,
    required this.displayName,
    this.isPrimary = true,
    required this.createdAt,
    this.lastVerifiedAt,
    required this.embedding,
    this.version = 'v1.0',
  });

  final String profileId;
  final String displayName;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime? lastVerifiedAt;
  final List<double> embedding;
  final String version;

  SpeakerProfile copyWith({
    String? profileId,
    String? displayName,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? lastVerifiedAt,
    List<double>? embedding,
    String? version,
  }) {
    return SpeakerProfile(
      profileId: profileId ?? this.profileId,
      displayName: displayName ?? this.displayName,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      embedding: embedding ?? this.embedding,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'displayName': displayName,
        'isPrimary': isPrimary,
        'createdAt': createdAt.toIso8601String(),
        'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
        'embedding': embedding,
        'version': version,
      };
}
