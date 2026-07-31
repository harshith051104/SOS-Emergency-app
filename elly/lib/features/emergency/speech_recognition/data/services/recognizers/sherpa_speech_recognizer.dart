/// sherpa_speech_recognizer.dart
///
/// Flutter-side Sherpa-ONNX SenseVoice speech recognizer.
///
/// Architecture:
///   Mobile (Flutter) ─── WAV bytes ──► Python Backend (/v1/stt/transcribe)
///                                         │
///                                         └── sherpa_onnx.OfflineRecognizer.from_sense_voice()
///                                               (on-device in Python process)
///
/// The heavy model inference runs in the Python backend via:
///   backend/app/services/sherpa_stt_service.py
///   backend/app/api/v1/stt.py  →  POST /v1/stt/transcribe
///
/// If backend is unavailable (offline scenario), falls back to
/// direct Groq Whisper transcription via /v1/stt/transcribe/groq.

library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:elly/core/config/backend_config.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/speech_recognition/domain/interfaces/i_speech_recognizer.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';

class SherpaSpeechRecognizer implements SpeechRecognizer {
  SherpaSpeechRecognizer({
    required this.config,
    this.timeoutSeconds = 12,
  });

  final SpeechConfig config;
  final int timeoutSeconds;
  bool _isCancelled = false;

  @override
  Future<SpeechRecognitionResult> transcribe(SpeechSession session) async {
    final timestamp = DateTime.now();
    _isCancelled = false;

    final pcmData = session.audioBuffer.pcmData;
    if (pcmData.isEmpty) {
      appLogger.warning('SherpaSpeechRecognizer: Audio buffer is empty.');
      return _emptyResult(session, timestamp);
    }

    final stopwatch = Stopwatch()..start();
    appLogger.info(
      'SherpaSpeechRecognizer: Sending ${pcmData.length} bytes of PCM '
      '(${session.durationMs}ms) to backend Sherpa-ONNX SenseVoice...',
    );

    String transcribedText = '';
    double confidence = 0.92;

    // ── 1. Build WAV file in memory (44-byte RIFF header + PCM) ─────────────
    final wavBytes = _buildWavBytes(pcmData);
    appLogger.info(
      'SherpaSpeechRecognizer: WAV built — ${wavBytes.length} bytes '
      '(PCM: ${pcmData.length} bytes, ${session.durationMs}ms) '
      '→ POST ${BackendConfig.sttTranscribeSherpa}',
    );

    // ── 2. POST WAV to Python backend /v1/stt/transcribe ────────────────────
    final result = await _postToBackend(
      endpoint: BackendConfig.sttTranscribeSherpa,
      wavBytes: wavBytes,
      sessionId: session.sessionId,
    );

    if (result != null && (result['text'] as String? ?? '').isNotEmpty) {
      transcribedText = (result['text'] as String).trim();
      confidence = (result['confidence'] as num?)?.toDouble() ?? 0.92;
      final inferenceMs = result['inference_ms'] as int? ?? 0;
      appLogger.info(
        'SherpaSpeechRecognizer: ✅ Sherpa SenseVoice -> '
        '"$transcribedText" (backend: ${inferenceMs}ms)',
      );
    } else if (result != null) {
      appLogger.warning(
        'SherpaSpeechRecognizer: ⚠️ Backend reached but returned EMPTY text. '
        'Response: $result',
      );
      // ── 3. Fallback: /v1/stt/transcribe/groq (Groq Whisper) ─────────────
      appLogger.info('SherpaSpeechRecognizer: Falling back to Groq Whisper...');
      final groqResult = await _postToBackend(
        endpoint: BackendConfig.sttTranscribeGroq,
        wavBytes: wavBytes,
        sessionId: session.sessionId,
      );
      if (groqResult != null) {
        transcribedText = (groqResult['text'] as String? ?? '').trim();
        confidence = (groqResult['confidence'] as num?)?.toDouble() ?? 0.85;
        if (transcribedText.isNotEmpty) {
          appLogger.info(
            'SherpaSpeechRecognizer: ✅ Groq Whisper fallback -> "$transcribedText"',
          );
        } else {
          appLogger.warning('SherpaSpeechRecognizer: ⚠️ Groq Whisper also returned empty text.');
        }
      }
    } else {
      appLogger.warning(
        'SherpaSpeechRecognizer: ❌ Backend UNREACHABLE (null response). '
        'Check adb reverse tcp:8000 tcp:8000 is active.',
      );
      // ── 3. Fallback to Groq when backend is completely unreachable ────────
      appLogger.info('SherpaSpeechRecognizer: Falling back to Groq Whisper (backend down)...');
      final groqResult = await _postToBackend(
        endpoint: BackendConfig.sttTranscribeGroq,
        wavBytes: wavBytes,
        sessionId: session.sessionId,
      );
      if (groqResult != null) {
        transcribedText = (groqResult['text'] as String? ?? '').trim();
        confidence = (groqResult['confidence'] as num?)?.toDouble() ?? 0.85;
        if (transcribedText.isNotEmpty) {
          appLogger.info(
            'SherpaSpeechRecognizer: ✅ Groq Whisper fallback -> "$transcribedText"',
          );
        }
      }
    }

    stopwatch.stop();

    if (_isCancelled) {
      return SpeechRecognitionResult(
        text: '[CANCELLED]',
        confidence: 0.0,
        durationMs: session.durationMs,
        language: config.preferredLanguage,
        inferenceTimeMs: stopwatch.elapsedMilliseconds,
        engine: SpeechEngine.sherpaSenseVoice,
        timestamp: timestamp,
      );
    }

    return SpeechRecognitionResult(
      text: transcribedText,
      confidence: transcribedText.isEmpty ? 0.0 : confidence,
      durationMs: session.durationMs,
      language: config.preferredLanguage,
      inferenceTimeMs: stopwatch.elapsedMilliseconds,
      engine: SpeechEngine.sherpaSenseVoice,
      timestamp: timestamp,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// POST a WAV file to a backend STT endpoint.
  /// Returns the parsed JSON body on success, or null on any error.
  Future<Map<String, dynamic>?> _postToBackend({
    required String endpoint,
    required Uint8List wavBytes,
    required String sessionId,
  }) async {
    try {
      final uri = Uri.parse(endpoint);
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            wavBytes,
            filename: 'audio_$sessionId.wav',
          ),
        );
      // Set content-type hint so backend knows it's a WAV file
      request.headers['Accept'] = 'application/json';

      final streamed = await request
          .send()
          .timeout(Duration(seconds: timeoutSeconds));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json;
      } else {
        appLogger.warning(
          'SherpaSpeechRecognizer: Backend $endpoint '
          'returned ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } on TimeoutException {
      appLogger.warning(
        'SherpaSpeechRecognizer: Request to $endpoint timed out '
        'after ${timeoutSeconds}s.',
      );
      return null;
    } catch (e) {
      appLogger.warning(
        'SherpaSpeechRecognizer: Network error calling $endpoint: $e',
      );
      return null;
    }
  }

  /// Builds an in-memory 16-bit PCM WAV file from raw PCM bytes.
  /// Matches the format expected by sherpa_onnx (16kHz, mono, int16).
  Uint8List _buildWavBytes(
    Uint8List pcmData, {
    int sampleRate = 16000,
    int channels = 1,
  }) {
    final byteRate = sampleRate * channels * 2;
    final blockAlign = channels * 2;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF chunk descriptor
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'
    // fmt sub-chunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little);          // sub-chunk size
    header.setUint16(20, 1, Endian.little);            // PCM format
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, 16, Endian.little);           // 16-bit depth
    // data sub-chunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, dataSize, Endian.little);

    final wav = Uint8List(44 + dataSize);
    wav.setAll(0, header.buffer.asUint8List());
    wav.setAll(44, pcmData);
    return wav;
  }

  SpeechRecognitionResult _emptyResult(
    SpeechSession session,
    DateTime timestamp,
  ) =>
      SpeechRecognitionResult(
        text: '',
        confidence: 0.0,
        durationMs: session.durationMs,
        language: config.preferredLanguage,
        inferenceTimeMs: 0,
        engine: SpeechEngine.sherpaSenseVoice,
        timestamp: timestamp,
      );

  @override
  Future<void> cancelCurrentRecognition() async {
    _isCancelled = true;
  }

  @override
  void dispose() {}
}
