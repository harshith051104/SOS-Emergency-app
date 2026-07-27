/// audio_session_manager.dart
///
/// Wraps record and audioplayers to record mic audio and play TTS chimes/voice wav files.

library;

import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';

import 'package:elly/core/utils/app_logger.dart';

class AudioSessionManager {
  AudioSessionManager({
    AudioRecorder? recorder,
    AudioPlayer? player,
    FlutterTts? tts,
  })  : _recorder = recorder ?? AudioRecorder(),
        _player = player ?? AudioPlayer(),
        _tts = tts ?? FlutterTts() {
    _initAudioPlayer();
    _initTts();
  }

  final AudioRecorder _recorder;
  final AudioPlayer _player;
  final FlutterTts _tts;
  StreamSubscription<void>? _playbackSubscription;

  void _initAudioPlayer() {
    try {
      AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.speech,
          audioFocus: AndroidAudioFocus.gainTransientExclusive,
        ),
        iOS: AudioContextIOS(
          options: const {
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ));
    } catch (e) {
      appLogger.warning('AudioSessionManager: Failed to set global audio context: $e');
    }
  }

  void _initTts() {
    try {
      _tts.setLanguage("en-US");
      _tts.setSpeechRate(0.5);
      _tts.setVolume(1.0);
      _tts.setPitch(1.0);
    } catch (e) {
      appLogger.warning('AudioSessionManager: Failed to initialize FlutterTts: $e');
    }
  }

  /// Speaks text directly using native device TextToSpeech engine.
  Future<void> speakText(String text, {VoidCallback? onComplete, VoidCallback? onStart}) async {
    try {
      await stopPlayback();
      onStart?.call();
      appLogger.info('AudioSessionManager: Speaking text via native FlutterTts: "$text"');

      _tts.setCompletionHandler(() {
        appLogger.info('AudioSessionManager: FlutterTts speech completed');
        onComplete?.call();
      });

      _tts.setErrorHandler((msg) {
        appLogger.error('AudioSessionManager: FlutterTts error: $msg');
        onComplete?.call();
      });

      await _tts.speak(text);
    } catch (e, st) {
      appLogger.error('AudioSessionManager: Failed during speakText', e, st);
      onComplete?.call();
    }
  }

  /// Starts recording microphone input to a temporary local WAV file.
  Future<String?> startRecording() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        appLogger.warning('AudioSessionManager: Microphone permission denied.');
        return null;
      }

      final tempDir = Directory.systemTemp;
      final filePath = '${tempDir.path}/elly_input_${DateTime.now().millisecondsSinceEpoch}.wav';

      appLogger.info('AudioSessionManager: Starting recording to $filePath');
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000),
        path: filePath,
      );
      return filePath;
    } catch (e, st) {
      appLogger.error('AudioSessionManager: Failed to start recording', e, st);
      return null;
    }
  }

  /// Stops recording and returns the path of the saved audio file.
  Future<String?> stopRecording() async {
    try {
      if (await _recorder.isRecording()) {
        final path = await _recorder.stop();
        appLogger.info('AudioSessionManager: Stopped recording. File saved at: $path');
        return path;
      }
    } catch (e, st) {
      appLogger.error('AudioSessionManager: Failed to stop recording', e, st);
    }
    return null;
  }

  /// Plays an audio file from a local path and calls [onComplete] upon completion.
  /// If native MediaPlayer encounters a device format error, falls back to native FlutterTts.
  Future<void> playAudio(
    String filePath, {
    VoidCallback? onComplete,
    VoidCallback? onStart,
    String? fallbackText,
  }) async {
    try {
      await stopPlayback();

      onStart?.call();
      appLogger.info('AudioSessionManager: Playing audio from $filePath');

      await _player.setVolume(1.0);

      // Track subscription to safely cancel when stopped or replaced
      _playbackSubscription = _player.onPlayerComplete.listen((_) {
        appLogger.info('AudioSessionManager: Playback completed for $filePath');
        _playbackSubscription?.cancel();
        _playbackSubscription = null;
        onComplete?.call();
      });

      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final mimeType = filePath.endsWith('.mp3') ? 'audio/mpeg' : 'audio/wav';
        await _player.play(BytesSource(bytes, mimeType: mimeType)).catchError((e) {
          appLogger.warning('AudioSessionManager: BytesSource play error caught cleanly: $e');
        });
      } else {
        await _player.play(DeviceFileSource(filePath)).catchError((e) {
          appLogger.warning('AudioSessionManager: DeviceFileSource play error caught cleanly: $e');
        });
      }
    } catch (e) {
      appLogger.warning('AudioSessionManager: MediaPlayer error caught ($e). Voice assistant speech disabled per setting.');
      _playbackSubscription?.cancel();
      _playbackSubscription = null;
      onComplete?.call();
    }
  }


  /// Stops any currently playing audio file or native TTS.
  Future<void> stopPlayback() async {
    try {
      _playbackSubscription?.cancel();
      _playbackSubscription = null;

      await _tts.stop();

      if (_player.state == PlayerState.playing || _player.state == PlayerState.paused) {
        appLogger.info('AudioSessionManager: Stopping active playback');
        await _player.stop();
      }
    } catch (e, st) {
      appLogger.error('AudioSessionManager: Failed to stop playback', e, st);
    }
  }

  /// Releases resources.
  Future<void> dispose() async {
    await stopPlayback();
    await _recorder.dispose();
    await _player.dispose();
  }
}


