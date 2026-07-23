/// groq_llm_service.dart
///
/// Handles sending prompt contexts and chat histories to the Groq Chat API.

library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/conversation_message.dart';

class GroqLlmService {
  GroqLlmService({
    required String apiKey,
    required String model,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _model = model,
        _client = httpClient ?? http.Client();

  final String _apiKey;
  final String _model;
  final http.Client _client;

  /// Sends a simple chat request and returns the full generated reply string.
  Future<String?> chat(List<ConversationMessage> history, {String? systemPrompt}) async {
    try {
      final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      appLogger.info('GroqLlmService: Requesting completion from $_model');

      final jsonMessages = <Map<String, String>>[];
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        jsonMessages.add({'role': 'system', 'content': systemPrompt});
      }
      for (final msg in history) {
        jsonMessages.add({
          'role': msg.role.name,
          'content': msg.text,
        });
      }

      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': jsonMessages,
          'temperature': 0.2,
          'max_tokens': 120,
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = data['choices'][0]['message']['content'] as String?;
        appLogger.info('GroqLlmService: Completed successfully: "${reply?.trim()}"');
        return reply;
      } else {
        appLogger.error('GroqLlmService: API error (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e, st) {
      appLogger.error('GroqLlmService: Network exception during completion request', e, st);
      return null;
    }
  }

  /// Sends a chat request with stream: true and yields token chunks as they arrive.
  Stream<String> streamChat(List<ConversationMessage> history, {String? systemPrompt}) async* {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    appLogger.info('GroqLlmService: Initiating stream connection for $_model');

    final jsonMessages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      jsonMessages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final msg in history) {
      jsonMessages.add({
        'role': msg.role.name,
        'content': msg.text,
      });
    }

    try {
      final request = http.Request('POST', uri)
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'model': _model,
          'messages': jsonMessages,
          'temperature': 0.2,
          'max_tokens': 120,
          'stream': true,
        });

      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 10));

      if (streamedResponse.statusCode == 200) {
        final stream = streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (trimmed == 'data: [DONE]') break;

          if (trimmed.startsWith('data: ')) {
            final jsonStr = trimmed.substring(6).trim();
            if (jsonStr.isEmpty) continue;
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              final delta = json['choices'][0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            } catch (_) {}
          }
        }
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();
        appLogger.error('GroqLlmService: Streaming failed (${streamedResponse.statusCode}): $errorBody');
        yield 'Failed to stream response.';
      }
    } catch (e, st) {
      appLogger.error('GroqLlmService: Exception inside streamChat', e, st);
      yield 'Network connection issue.';
    }
  }
}
