import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_config.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_state.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_request.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_result.dart';
import 'package:elly/features/emergency/speaker_verification/presentation/providers/speaker_verification_providers.dart';
import 'package:elly/features/emergency/speaker_verification/data/services/verifiers/mock_speaker_verifier.dart';

void main() {
  group('SpeakerVerificationController Unit & Lifecycle Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          speakerVerificationConfigProvider.overrideWith(
            (ref) => const SpeakerVerificationConfig(verifierType: SpeakerVerificationMethod.mock),
          ),
          speakerVerifierProvider.overrideWithValue(
            MockSpeakerVerifier(forcedConfidence: 0.96),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle', () {
      final state = container.read(speakerVerificationControllerProvider);

      expect(state.status, equals(SpeakerVerificationStatus.idle));
      expect(state.lastResult, isNull);
    });

    test('verifySpeaker updates state to completed with result', () async {
      final controller = container.read(speakerVerificationControllerProvider.notifier);

      final req = SpeakerVerificationRequest(
        sessionId: 'sess_test_100',
        audioBuffer: AudioBuffer(pcmData: Uint8List(16000 * 2)),
        timestamp: DateTime.now(),
      );

      await controller.verifySpeaker(req);

      final state = container.read(speakerVerificationControllerProvider);
      expect(state.status, equals(SpeakerVerificationStatus.completed));
      expect(state.lastResult, isNotNull);
      expect(state.lastResult!.match, isTrue);
      expect(state.lastResult!.confidence, equals(0.96));
    });
  });
}
