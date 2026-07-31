/// vad_providers.dart
///
/// Riverpod dependency injection definitions for Voice Activity Detection (VAD) feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/features/emergency/voice_trigger/domain/interfaces/i_voice_activity_detector.dart';
import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_state.dart';
import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_config.dart';
import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_telemetry.dart';
import 'package:elly/features/emergency/voice_trigger/data/channels/vad_platform_channel.dart';
import 'package:elly/features/emergency/voice_trigger/data/services/silero_vad_detector.dart';
import 'package:elly/features/emergency/voice_trigger/data/services/vad_telemetry_service.dart';
import 'package:elly/features/emergency/voice_trigger/presentation/controllers/vad_controller.dart';

final vadConfigProvider = StateProvider<VadConfig>((ref) {
  return const VadConfig();
});

final voiceActivityDetectorProvider = Provider<VoiceActivityDetector>((ref) {
  final config = ref.watch(vadConfigProvider);
  final detector = SileroVadDetector(config: config);
  ref.onDispose(() => detector.dispose());
  return detector;
});

final vadPlatformChannelProvider = Provider<VadPlatformChannel>((ref) {
  return const VadPlatformChannel();
});

final vadTelemetryServiceProvider = Provider<VadTelemetryService>((ref) {
  final service = VadTelemetryService();
  ref.onDispose(() => service.stopTracking());
  return service;
});

final vadControllerProvider = StateNotifierProvider<VadController, VadState>((ref) {
  final channel = ref.watch(vadPlatformChannelProvider);
  final telemetry = ref.watch(vadTelemetryServiceProvider);
  final config = ref.watch(vadConfigProvider);

  return VadController(
    ref,
    channel: channel,
    telemetryService: telemetry,
    config: config,
  );
});

final vadTelemetryProvider = Provider<VadTelemetry>((ref) {
  final service = ref.watch(vadTelemetryServiceProvider);
  return service.telemetry;
});
