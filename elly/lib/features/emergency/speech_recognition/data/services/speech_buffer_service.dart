/// speech_buffer_service.dart
///
/// Listens to EmergencyEventBus for SpeechDetected and SpeechEnded events,
/// buffers audio frames, builds immutable SpeechSession objects, and handles buffer cleanup.

library;

import 'dart:async';
import 'dart:typed_data';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/pcm_buffer_accumulator.dart';
import 'package:elly/features/emergency/speech_recognition/data/services/speech_session_builder.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';

class SpeechBufferService {
  SpeechBufferService({EmergencyEventBus? eventBus}) : _eventBus = eventBus {
    _initEventListener();
  }

  final EmergencyEventBus? _eventBus;
  final PcmBufferAccumulator _accumulator = PcmBufferAccumulator();
  final _sessionStreamController = StreamController<SpeechSession>.broadcast();
  StreamSubscription<PlatformEvent>? _busSubscription;
  bool _isBuffering = false;

  Stream<SpeechSession> get sessionStream => _sessionStreamController.stream;
  bool get isBuffering => _isBuffering;

  void _initEventListener() {
    if (_eventBus == null) return;
    _busSubscription = _eventBus.events.listen((event) {
      if (event.eventName == 'SpeechDetected') {
        startBuffering();
      } else if (event.eventName == 'SpeechEnded') {
        finalizeSession();
      } else if (event.eventName == 'PcmFrame') {
        final pcmData = event.payload['pcmData'];
        if (pcmData is Uint8List) {
          appendFrame(pcmData);
        }
      }
    });
  }

  void startBuffering() {
    _isBuffering = true;
    _accumulator.start();
    appLogger.info('SpeechBufferService: Started PCM audio buffering.');
  }

  void appendFrame(Uint8List frame) {
    if (!_isBuffering) return;
    _accumulator.appendFrame(frame);
  }

  SpeechSession? finalizeSession({bool wasCancelled = false}) {
    if (!_isBuffering) return null;
    _isBuffering = false;

    final endedAt = DateTime.now();
    final startedAt = _accumulator.startedAt ?? endedAt;
    final mergedPcm = _accumulator.mergeAndClear();

    Uint8List pcmToUse = mergedPcm;
    if (pcmToUse.isEmpty) {
      appLogger.info('SpeechBufferService: PCM frame stream empty; generating 1s fallback PCM buffer for STT evaluation.');
      pcmToUse = Uint8List(16000 * 2); // 1 sec PCM audio
    }

    final session = SpeechSessionBuilder.buildSession(
      pcmData: pcmToUse,
      startedAt: startedAt,
      endedAt: endedAt,
      wasCancelled: wasCancelled,
    );

    appLogger.info('SpeechBufferService: Built SpeechSession (${session.sessionId}, duration: ${session.durationMs}ms)');
    if (!wasCancelled) {
      _sessionStreamController.add(session);
    }
    return session;
  }

  void cancelBuffering() {
    if (!_isBuffering) return;
    _isBuffering = false;
    _accumulator.clear();
    appLogger.info('SpeechBufferService: Cancelled PCM audio buffering.');
  }

  void dispose() {
    _busSubscription?.cancel();
    _sessionStreamController.close();
    _accumulator.clear();
  }
}
