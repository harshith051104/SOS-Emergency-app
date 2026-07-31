/// vad_controller.dart
///
/// Master StateNotifier controller managing Voice Activity Detection (VAD) service lifecycle,
/// Android Method/Event Channel bridge events, structured logging, and publishing to EmergencyEventBus.

library;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_state.dart';
import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_config.dart';
import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_events.dart';
import 'package:elly/features/emergency/voice_trigger/data/channels/vad_platform_channel.dart';
import 'package:elly/features/emergency/voice_trigger/data/services/vad_telemetry_service.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/sos/presentation/providers/sos_trigger_config_provider.dart';

class VadController extends StateNotifier<VadState> {
  VadController(
    this._ref, {
    VadPlatformChannel? channel,
    VadTelemetryService? telemetryService,
    VadConfig? config,
  })  : _channel = channel ?? const VadPlatformChannel(),
        _telemetry = telemetryService ?? VadTelemetryService(),
        super(VadState(speechThreshold: config?.speechThreshold ?? 0.5)) {
    _initChannelListener();
  }

  final Ref _ref;
  final VadPlatformChannel _channel;
  final VadTelemetryService _telemetry;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  void _initChannelListener() {
    if (!_channel.isSupported) {
      state = state.copyWith(status: VadStatus.unsupported);
      return;
    }

    _eventSubscription = _channel.vadEventStream().listen(
      _handleNativeEvent,
      onError: (dynamic error) {
        appLogger.error('VadController: Native EventChannel error: $error');
        _handleError(error.toString());
      },
    );
  }

  void updateThreshold(double newThreshold) {
    state = state.copyWith(speechThreshold: newThreshold);
    appLogger.info('VadController: Updated speech threshold to $newThreshold');
  }

  /// Starts the Voice Activity Detection background protection service.
  Future<bool> startVadService() async {
    final config = _ref.read(sosTriggerConfigProvider);
    if (!config.isVoiceTriggerEnabled) {
      appLogger.info('VadController: Voice Trigger is disabled in settings. Skipping VAD start.');
      return false;
    }

    if (state.isServiceRunning) {
      appLogger.info('VadController: Service is already running.');
      return true;
    }

    state = state.copyWith(status: VadStatus.starting, clearError: true);

    // 1. Validate Microphone Permission
    final permStatus = await Permission.microphone.status;
    if (!permStatus.isGranted) {
      appLogger.info('VadController: Requesting microphone permission...');
      final requested = await Permission.microphone.request();
      if (!requested.isGranted) {
        const msg = 'Microphone permission denied by user.';
        appLogger.warning('VadController: $msg');
        _handleError(msg);
        return false;
      }
    }

    // 2. Launch Android Foreground Service
    final started = await _channel.startService();
    if (started) {
      state = state.copyWith(
        status: VadStatus.listening,
        isServiceRunning: true,
        clearError: true,
      );
      _telemetry.startTracking();

      final event = VadServiceStartedPlatformEvent(timestamp: DateTime.now());
      _publishEvent(event);
      appLogger.info('VadController: VAD Protection Service started successfully.');
      return true;
    } else {
      const msg = 'Failed to launch Android VAD Foreground Service.';
      appLogger.error('VadController: $msg');
      _handleError(msg);
      return false;
    }
  }

  /// Stops the Voice Activity Detection background protection service.
  Future<bool> stopVadService() async {
    final stopped = await _channel.stopService();
    _telemetry.stopTracking();

    state = state.copyWith(
      status: VadStatus.stopped,
      isServiceRunning: false,
      isSpeechDetected: false,
    );

    final event = VadServiceStoppedPlatformEvent(timestamp: DateTime.now());
    _publishEvent(event);
    appLogger.info('VadController: VAD Protection Service stopped.');
    return stopped;
  }

  void _handleNativeEvent(Map<String, dynamic> data) {
    final eventName = data['event'] as String?;
    final timestamp = DateTime.now();

    switch (eventName) {
      case 'serviceStarted':
        state = state.copyWith(
          status: VadStatus.listening,
          isServiceRunning: true,
          clearError: true,
        );
        break;

      case 'serviceStopped':
        state = state.copyWith(
          status: VadStatus.stopped,
          isServiceRunning: false,
          isSpeechDetected: false,
        );
        break;

      case 'vadTelemetryUpdate':
        final prob = (data['probability'] as num?)?.toDouble() ?? 0.0;
        state = state.copyWith(
          speechProbability: prob,
        );
        break;

      case 'speechDetected':
        final prob = (data['probability'] as num?)?.toDouble() ?? 1.0;
        final latency = (data['inferenceMs'] as num?)?.toDouble() ?? 0.0;
        state = state.copyWith(
          status: VadStatus.speechDetected,
          isSpeechDetected: true,
          lastSpeechDetectedAt: timestamp,
          speechProbability: prob,
        );
        _telemetry.recordSpeechDetected();

        final event = SpeechDetectedPlatformEvent(
          probability: prob,
          timestamp: timestamp,
        );
        _publishEvent(event);
        appLogger.info('VadController: 🗣️ Official Silero ONNX Speech Detected (prob: ${prob.toStringAsFixed(3)}, ONNX latency: ${latency.toStringAsFixed(2)}ms)');
        break;

      case 'speechEnded':
        final prob = (data['probability'] as num?)?.toDouble() ?? 0.0;
        state = state.copyWith(
          status: VadStatus.listening,
          isSpeechDetected: false,
          speechProbability: prob,
        );

        final event = SpeechEndedPlatformEvent(
          probability: prob,
          timestamp: timestamp,
        );
        _publishEvent(event);
        appLogger.info('VadController: 🔇 Official Silero ONNX Speech Ended (prob: ${prob.toStringAsFixed(3)})');
        break;

      case 'pcmFrame':
        final rawPcm = data['pcm'];
        if (rawPcm is Uint8List) {
          final event = PcmFramePlatformEvent(
            pcmData: rawPcm,
            timestamp: timestamp,
          );
          _publishEvent(event);
        }
        break;

      case 'audioRoutingChanged':
        final reason = data['reason'] as String? ?? 'unknown';
        appLogger.info('VadController: Audio routing changed ($reason)');
        break;

      case 'error':
        final msg = data['message'] as String? ?? 'VAD Service Native Error';
        _handleError(msg);
        break;

      default:
        break;
    }
  }

  void _handleError(String message) {
    state = state.copyWith(
      status: VadStatus.error,
      isServiceRunning: false,
      isSpeechDetected: false,
      errorMessage: message,
    );

    final event = VadErrorPlatformEvent(
      errorMessage: message,
      timestamp: DateTime.now(),
    );
    _publishEvent(event);
  }

  void _publishEvent(PlatformEvent event) {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      bus.publish(event.eventName, event.payload);
    } catch (e) {
      appLogger.warning('VadController: Could not publish event to EmergencyEventBus: $e');
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _telemetry.stopTracking();
    super.dispose();
  }
}
