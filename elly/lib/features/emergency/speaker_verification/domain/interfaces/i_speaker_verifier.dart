/// i_speaker_verifier.dart
///
/// Abstraction interface for offline Speaker Verification engines.

library;

import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_request.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';

abstract class SpeakerVerifier {
  Future<SpeakerVerificationResult> verify(SpeakerVerificationRequest request);
  void dispose();
}
