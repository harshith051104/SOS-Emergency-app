/// voice_scheduler.dart
///
/// Priority-based voice event queue scheduler with interruption support.

library;

import 'dart:async';

import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/voice_event.dart';

class VoiceScheduler {
  VoiceScheduler({
    required Future<void> Function(String text, bool isCritical) onSpeak,
    required Future<void> Function() onStopPlayback,
  })  : _onSpeak = onSpeak,
        _onStopPlayback = onStopPlayback;

  final Future<void> Function(String text, bool isCritical) _onSpeak;
  final Future<void> Function() _onStopPlayback;

  final List<VoiceEvent> _queue = [];
  VoiceEvent? _currentEvent;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;
  List<VoiceEvent> get queue => List.unmodifiable(_queue);

  /// The pre-synthesized audio file path from the currently playing event.
  /// Returns null for brain-triggered events (battery/location alerts) that
  /// skip [AssistantController._queueSentence] and have no pre-cached audio.
  String? get currentEventAudioPath => _currentEvent?.audioPath;

  /// Queues a new [VoiceEvent] and processes it according to priority.
  Future<void> queueEvent(VoiceEvent event) async {
    appLogger.info('VoiceScheduler: Queueing event: "${event.text}" [Priority: ${event.priority.name}]');

    if (event.priority == VoicePriority.critical) {
      // Critical alerts interrupt standard dialogue immediately
      if (_currentEvent != null && _currentEvent!.priority != VoicePriority.critical) {
        appLogger.info('VoiceScheduler: Critical event interrupting current standard speech: "${_currentEvent!.text}"');
        await interrupt();
        // Clear all non-critical queued events to prevent stale warnings
        _queue.removeWhere((e) => e.priority != VoicePriority.critical);
      }
      
      // Add to front of queue
      _queue.insert(0, event);
    } else {
      // Normal enqueue
      _queue.add(event);
      // Sort queue so critical/higher priority events are processed first
      _queue.sort((a, b) => a.priority.value.compareTo(b.priority.value));
    }

    if (!_isSpeaking) {
      // Defer to a microtask to ensure we never kick off state-changing
      // async work synchronously inside a ref.listen / build / layout phase.
      scheduleMicrotask(_playNext);
    }
  }

  /// Cancels currently playing audio, clears current event states.
  Future<void> interrupt() async {
    appLogger.info('VoiceScheduler: Interrupting voice output.');
    _isSpeaking = false;
    _currentEvent = null;
    await _onStopPlayback();
  }

  /// Clears all queued events.
  void clearQueue() {
    _queue.clear();
  }

  /// Internal worker: plays the next item in the sorted queue.
  Future<void> _playNext() async {
    if (_queue.isEmpty) {
      _isSpeaking = false;
      _currentEvent = null;
      return;
    }

    _isSpeaking = true;
    final event = _queue.removeAt(0);
    _currentEvent = event;

    try {
      appLogger.info('VoiceScheduler: Speaking next event: "${event.text}"');
      final isCritical = event.priority == VoicePriority.critical;
      
      // Invoke speech callback and await its completion
      await _onSpeak(event.text, isCritical);
      
      // Move to next event once finished
      if (_isSpeaking && _currentEvent == event) {
        scheduleMicrotask(_playNext);
      }
    } catch (e, st) {
      appLogger.error('VoiceScheduler: Error playing voice event', e, st);
      scheduleMicrotask(_playNext);
    }
  }

  /// Invoked when audio playback finishes successfully.
  void notifyPlaybackComplete() {
    appLogger.info('VoiceScheduler: Active speak event playback finished.');
    if (_isSpeaking) {
      scheduleMicrotask(_playNext);
    }
  }
}
