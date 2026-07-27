/// speech_recognition_service.dart
///
/// Sends recorded audio files to the Groq Whisper API for transcription.

library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:elly/core/utils/app_logger.dart';

abstract class SpeechRecognitionService {
  Future<String?> transcribe(String filePath);
}

class GroqSpeechRecognitionService implements SpeechRecognitionService {
  GroqSpeechRecognitionService({
    required String apiKey,
    required String model,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _model = model,
        _client = httpClient ?? http.Client();

  final String _apiKey;
  final String _model;
  final http.Client _client;

  @override
  Future<String?> transcribe(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        appLogger.error('GroqSpeechRecognitionService: Transcription audio file does not exist: $filePath');
        return null;
      }

      final uri = Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions');
      appLogger.info('GroqSpeechRecognitionService: Uploading $filePath to Groq Whisper using $_model');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..fields['model'] = _model
        ..fields['response_format'] = 'json'
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 12));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['text'] as String?;
        appLogger.info('GroqSpeechRecognitionService: Transcription success: "$text"');
        return text;
      } else {
        appLogger.error('GroqSpeechRecognitionService: API error (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e, st) {
      appLogger.error('GroqSpeechRecognitionService: Network/parsing exception during transcription', e, st);
      return null;
    }
  }
}
