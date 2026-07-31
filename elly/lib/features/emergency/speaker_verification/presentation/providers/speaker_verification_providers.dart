/// speaker_verification_providers.dart
///
/// Riverpod dependency injection definitions for Speaker Verification feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/features/emergency/speaker_verification/domain/interfaces/i_speaker_verifier.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_config.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_state.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_telemetry.dart';
import 'package:elly/features/emergency/speaker_verification/data/services/enrollment_service.dart';
import 'package:elly/features/emergency/speaker_verification/data/services/speaker_verification_service.dart';
import 'package:elly/features/emergency/speaker_verification/data/services/verifiers/embedding_speaker_verifier.dart';
import 'package:elly/features/emergency/speaker_verification/data/services/verifiers/mock_speaker_verifier.dart';
import 'package:elly/features/emergency/speaker_verification/presentation/controllers/speaker_verification_controller.dart';

final speakerVerificationConfigProvider = StateProvider<SpeakerVerificationConfig>((ref) {
  return const SpeakerVerificationConfig();
});

final enrollmentServiceProvider = Provider<EnrollmentService>((ref) {
  return EnrollmentService();
});

/// Direct Riverpod DI Selection for SpeakerVerifier implementation.
final speakerVerifierProvider = Provider<SpeakerVerifier>((ref) {
  final config = ref.watch(speakerVerificationConfigProvider);
  final enrollment = ref.watch(enrollmentServiceProvider);

  switch (config.verifierType) {
    case SpeakerVerificationMethod.embedding:
      final verifier = EmbeddingSpeakerVerifier(config: config, enrollmentService: enrollment);
      ref.onDispose(() => verifier.dispose());
      return verifier;
    case SpeakerVerificationMethod.mock:
      final mock = MockSpeakerVerifier();
      ref.onDispose(() => mock.dispose());
      return mock;
  }
});

final speakerVerificationServiceProvider = Provider<SpeakerVerificationService>((ref) {
  final verifier = ref.watch(speakerVerifierProvider);
  final config = ref.watch(speakerVerificationConfigProvider);

  final service = SpeakerVerificationService(
    verifier: verifier,
    timeoutMs: config.maxLatencyMs,
    minDurationMs: config.minimumAudioDurationMs,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final speakerVerificationControllerProvider = StateNotifierProvider<SpeakerVerificationController, SpeakerVerificationState>((ref) {
  final service = ref.watch(speakerVerificationServiceProvider);
  final enrollment = ref.watch(enrollmentServiceProvider);

  return SpeakerVerificationController(
    ref,
    service: service,
    enrollmentService: enrollment,
  );
});

final speakerVerificationTelemetryProvider = Provider<SpeakerVerificationTelemetry>((ref) {
  final service = ref.watch(speakerVerificationServiceProvider);
  return service.telemetry;
});
