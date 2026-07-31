/// vad_events.dart
///
/// Strongly typed PlatformEvent extensions for Voice Activity Detection engine.

library;

import 'dart:typed_data';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';

class VadServiceStartedPlatformEvent extends PlatformEvent {
  VadServiceStartedPlatformEvent({
    required super.timestamp,
    Map<String, dynamic> extra = const {},
  }) : super(
          eventId: 'evt_vad_start_${timestamp.millisecondsSinceEpoch}',
          eventName: 'VadServiceStarted',
          payload: {
            'status': 'started',
            'timestamp': timestamp.toIso8601String(),
            ...extra,
          },
        );
}

class VadServiceStoppedPlatformEvent extends PlatformEvent {
  VadServiceStoppedPlatformEvent({
    required super.timestamp,
    Map<String, dynamic> extra = const {},
  }) : super(
          eventId: 'evt_vad_stop_${timestamp.millisecondsSinceEpoch}',
          eventName: 'VadServiceStopped',
          payload: {
            'status': 'stopped',
            'timestamp': timestamp.toIso8601String(),
            ...extra,
          },
        );
}

class SpeechDetectedPlatformEvent extends PlatformEvent {
  SpeechDetectedPlatformEvent({
    required double probability,
    required super.timestamp,
  }) : super(
          eventId: 'evt_speech_det_${timestamp.millisecondsSinceEpoch}',
          eventName: 'SpeechDetected',
          payload: {
            'speechDetected': true,
            'probability': probability,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class SpeechEndedPlatformEvent extends PlatformEvent {
  SpeechEndedPlatformEvent({
    required double probability,
    required super.timestamp,
  }) : super(
          eventId: 'evt_speech_end_${timestamp.millisecondsSinceEpoch}',
          eventName: 'SpeechEnded',
          payload: {
            'speechDetected': false,
            'probability': probability,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class PcmFramePlatformEvent extends PlatformEvent {
  PcmFramePlatformEvent({
    required Uint8List pcmData,
    required super.timestamp,
  }) : super(
          eventId: 'evt_pcm_${timestamp.millisecondsSinceEpoch}',
          eventName: 'PcmFrame',
          payload: {
            'pcmData': pcmData,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class VadPausedPlatformEvent extends PlatformEvent {
  VadPausedPlatformEvent({
    required String reason,
    required super.timestamp,
  }) : super(
          eventId: 'evt_vad_pause_${timestamp.millisecondsSinceEpoch}',
          eventName: 'VadPaused',
          payload: {
            'status': 'paused',
            'reason': reason,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}

class VadErrorPlatformEvent extends PlatformEvent {
  VadErrorPlatformEvent({
    required String errorMessage,
    required super.timestamp,
  }) : super(
          eventId: 'evt_vad_err_${timestamp.millisecondsSinceEpoch}',
          eventName: 'VadError',
          payload: {
            'error': errorMessage,
            'timestamp': timestamp.toIso8601String(),
          },
        );
}
