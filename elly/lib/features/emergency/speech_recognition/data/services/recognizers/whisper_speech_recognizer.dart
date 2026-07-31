import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/speech_recognition/domain/interfaces/i_speech_recognizer.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_recognition_result.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';

class WhisperSpeechRecognizer implements SpeechRecognizer {
  WhisperSpeechRecognizer({
    required this.config,
    this.apiKey = '',
  });

  final SpeechConfig config;
  final String apiKey;
  bool _isCancelled = false;

  @override
  Future<SpeechRecognitionResult> transcribe(SpeechSession session) async {
    final timestamp = DateTime.now();
    _isCancelled = false;

    final pcmData = session.audioBuffer.pcmData;
    if (pcmData.isEmpty) {
      appLogger.warning('WhisperSpeechRecognizer: Audio buffer is empty.');
      return SpeechRecognitionResult(
        text: '',
        confidence: 0.0,
        durationMs: session.durationMs,
        language: config.preferredLanguage,
        inferenceTimeMs: 0,
        engine: SpeechEngine.whisper,
        timestamp: timestamp,
      );
    }

    final stopwatch = Stopwatch()..start();
    appLogger.info('WhisperSpeechRecognizer: Transcribing real audio (${pcmData.length} bytes, ${session.durationMs}ms)');

    String transcribedText = '';
    double confidence = 0.85;

    final effectiveKey = apiKey.isNotEmpty 
        ? apiKey 
        : const String.fromEnvironment('GROQ_API_KEY');

    if (effectiveKey.isNotEmpty) {
      try {
        final wavBytes = _buildWavBytes(pcmData);
        final tempFile = File('${Directory.systemTemp.path}/stt_${session.sessionId}.wav');
        await tempFile.writeAsBytes(wavBytes);

        final uri = Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions');
        final request = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $effectiveKey'
          ..fields['model'] = 'whisper-large-v3-turbo'
          ..fields['response_format'] = 'json'
          ..files.add(await http.MultipartFile.fromPath('file', tempFile.path));

        final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          transcribedText = (json['text'] as String? ?? '').trim();
          confidence = 0.95;
          appLogger.info('WhisperSpeechRecognizer: 🗣️ Groq STT Success -> "$transcribedText"');
        } else {
          appLogger.error('WhisperSpeechRecognizer: Groq STT API Error ${response.statusCode}: ${response.body}');
        }

        try {
          if (await tempFile.exists()) await tempFile.delete();
        } catch (_) {}
      } catch (e) {
        appLogger.error('WhisperSpeechRecognizer: Groq network transcription exception: $e');
      }
    }

    if (transcribedText.isEmpty) {
      transcribedText = '';
      confidence = 0.0;
    }

    stopwatch.stop();

    if (_isCancelled) {
      return SpeechRecognitionResult(
        text: '[CANCELLED]',
        confidence: 0.0,
        durationMs: session.durationMs,
        language: config.preferredLanguage,
        inferenceTimeMs: stopwatch.elapsedMilliseconds,
        engine: SpeechEngine.whisper,
        timestamp: timestamp,
      );
    }

    return SpeechRecognitionResult(
      text: transcribedText,
      confidence: confidence,
      durationMs: session.durationMs,
      language: config.preferredLanguage,
      inferenceTimeMs: stopwatch.elapsedMilliseconds,
      engine: SpeechEngine.whisper,
      timestamp: timestamp,
    );
  }

  Uint8List _buildWavBytes(Uint8List pcmData, {int sampleRate = 16000, int channels = 1}) {
    final fileSize = 36 + pcmData.length;
    final byteRate = sampleRate * channels * 2;
    final blockAlign = channels * 2;

    final header = ByteData(44);
    header.setUint8(0, 0x52); header.setUint8(1, 0x49); header.setUint8(2, 0x46); header.setUint8(3, 0x46);
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57); header.setUint8(9, 0x41); header.setUint8(10, 0x56); header.setUint8(11, 0x45);
    header.setUint8(12, 0x66); header.setUint8(13, 0x6D); header.setUint8(14, 0x74); header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint8(36, 0x64); header.setUint8(37, 0x61); header.setUint8(38, 0x74); header.setUint8(39, 0x61);
    header.setUint32(40, pcmData.length, Endian.little);

    final wav = Uint8List(44 + pcmData.length);
    wav.setAll(0, header.buffer.asUint8List());
    wav.setAll(44, pcmData);
    return wav;
  }

  @override
  Future<void> cancelCurrentRecognition() async {
    _isCancelled = true;
  }

  @override
  void dispose() {}
}
