import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_state.dart';
import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_config.dart';
import 'package:elly/features/emergency/voice_trigger/presentation/providers/vad_providers.dart';
import 'package:elly/features/emergency/voice_trigger/data/channels/vad_platform_channel.dart';
import 'package:elly/features/emergency/voice_trigger/data/services/vad_telemetry_service.dart';

class MockVadPlatformChannel implements VadPlatformChannel {
  bool isServiceStarted = false;
  bool forceFail = false;

  @override
  bool get isSupported => true;

  @override
  Future<bool> startService() async {
    if (forceFail) return false;
    isServiceStarted = true;
    return true;
  }

  @override
  Future<bool> stopService() async {
    isServiceStarted = false;
    return true;
  }

  @override
  Future<bool> isServiceRunning() async => isServiceStarted;

  @override
  Stream<Map<String, dynamic>> vadEventStream() => const Stream.empty();
}

void main() {
  group('VadController Unit & Lifecycle Tests', () {
    late ProviderContainer container;
    late MockVadPlatformChannel mockChannel;
    late VadTelemetryService telemetryService;

    setUp(() {
      mockChannel = MockVadPlatformChannel();
      telemetryService = VadTelemetryService();
      container = ProviderContainer(
        overrides: [
          vadPlatformChannelProvider.overrideWithValue(mockChannel),
          vadTelemetryServiceProvider.overrideWithValue(telemetryService),
          vadConfigProvider.overrideWith((ref) => const VadConfig()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      telemetryService.stopTracking();
    });

    test('Initial state is idle', () {
      final state = container.read(vadControllerProvider);

      expect(state.status, equals(VadStatus.idle));
      expect(state.isServiceRunning, isFalse);
      expect(state.isSpeechDetected, isFalse);
    });

    test('Threshold can be updated dynamically', () {
      final controller = container.read(vadControllerProvider.notifier);

      controller.updateThreshold(0.75);
      final state = container.read(vadControllerProvider);
      expect(state.speechThreshold, equals(0.75));
    });
  });
}
