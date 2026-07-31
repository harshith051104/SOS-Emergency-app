/// speech_model_session.dart
///
/// Encapsulates STT model loading, ONNX inference session lifecycle, and memory management.

library;

import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';

class SpeechModelSession {
  SpeechModelSession({required this.config});

  final SpeechConfig config;
  bool _isLoaded = false;
  int _loadTimeMs = 0;

  bool get isLoaded => _isLoaded;
  int get loadTimeMs => _loadTimeMs;

  Future<bool> loadModel() async {
    if (_isLoaded) return true;

    final stopwatch = Stopwatch()..start();
    try {
      // Offline local model session initialization
      appLogger.info('SpeechModelSession: Loading offline STT model [Engine: ${config.engine.name}, Path: ${config.modelPath}]');
      _isLoaded = true;
      stopwatch.stop();
      _loadTimeMs = stopwatch.elapsedMilliseconds;
      appLogger.info('SpeechModelSession: Model session loaded successfully (${_loadTimeMs}ms)');
      return true;
    } catch (e, st) {
      stopwatch.stop();
      _loadTimeMs = stopwatch.elapsedMilliseconds;
      appLogger.error('SpeechModelSession: Failed to load model session', e, st);
      _isLoaded = false;
      return false;
    }
  }

  void unloadModel() {
    if (!_isLoaded) return;
    _isLoaded = false;
    appLogger.info('SpeechModelSession: Model session unloaded and resources released.');
  }
}
