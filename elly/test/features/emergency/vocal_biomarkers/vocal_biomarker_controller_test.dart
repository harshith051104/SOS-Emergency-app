/// vocal_biomarker_controller_test.dart
///
/// Unit tests for VocalBiomarkerController state management, Riverpod integration, and event bus interaction.

library;

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/vocal_biomarkers/domain/entities/vocal_biomarker_request.dart';
import 'package:elly/features/emergency/vocal_biomarkers/domain/entities/vocal_biomarker_state.dart';
import 'package:elly/features/emergency/vocal_biomarkers/presentation/providers/vocal_biomarker_providers.dart';

void main() {
  group('VocalBiomarkerController Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle', () {
      final state = container.read(vocalBiomarkerControllerProvider);
      expect(state.status, equals(VocalBiomarkerStatus.idle));
      expect(state.lastResult, isNull);
      expect(state.activeSessionId, isNull);
    });

    test('analyzeBiomarkers executes analysis and updates state to completed', () async {
      final controller = container.read(vocalBiomarkerControllerProvider.notifier);

      final pcmBytes = Uint8List(16000 * 2 * 1); // 1 sec
      final request = VocalBiomarkerRequest(
        sessionId: 'controller_test_1',
        audioBuffer: AudioBuffer(pcmData: pcmBytes),
        timestamp: DateTime.now(),
      );

      await controller.analyzeBiomarkers(request);

      final state = container.read(vocalBiomarkerControllerProvider);
      expect(state.status, equals(VocalBiomarkerStatus.completed));
      expect(state.lastResult, isNotNull);
      expect(state.lastResult?.sessionId, equals('controller_test_1'));
      expect(state.lastResult?.dspVersion, equals('v1.0.0-dsp'));
      expect(state.lastResult?.algorithmVersion, equals('v1.0.0-acoustic'));
    });
  });
}
