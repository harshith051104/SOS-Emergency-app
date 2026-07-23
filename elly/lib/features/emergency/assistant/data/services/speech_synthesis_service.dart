/// speech_synthesis_service.dart
///
/// Converts text responses to spoken audio using the Groq Orpheus API,
/// with hash-based local caching and offline fallback capabilities.

library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:elly/core/utils/app_logger.dart';

abstract class SpeechSynthesisService {
  Future<String?> synthesize(String text);
  void recordCacheHit();
  int get cacheHitsCount;
}

class GroqSpeechSynthesisService implements SpeechSynthesisService {
  GroqSpeechSynthesisService({
    required String apiKey,
    required String model,
    required String voice,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _model = model,
        _voice = voice,
        _client = httpClient ?? http.Client();

  final String _apiKey;
  final String _model;
  final String _voice;
  final http.Client _client;
  int _cacheHits = 0;

  @override
  int get cacheHitsCount => _cacheHits;

  @override
  void recordCacheHit() {
    _cacheHits++;
  }

  @override
  Future<String?> synthesize(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return null;

    final safeTempPath = Directory.systemTemp.path.replaceAll('code_cache', 'cache');
    final cacheDir = Directory(safeTempPath);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    // Calculate a simple deterministic text hash for local cache lookup
    final textHash = cleanText.toLowerCase().hashCode.toString();
    final cacheFile = File('${cacheDir.path}/tts_cache_$textHash.wav');

    // Force delete stale cache files to guarantee fresh API fetch with patched header
    if (await cacheFile.exists()) {
      try {
        await cacheFile.delete();
      } catch (_) {}
    }

    // 2. Fetch from Groq Orpheus API
    try {
      final uri = Uri.parse('https://api.groq.com/openai/v1/audio/speech');
      appLogger.info('GroqSpeechSynthesisService: Cache MISS. Synthesizing via Groq Orpheus: "$cleanText"');

      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'input': cleanText,
          'voice': _voice,
          'response_format': 'wav',
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final bytes = Uint8List.fromList(response.bodyBytes);
        if (bytes.length >= 44) {
          final headerHex = bytes.sublist(0, 44).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
          appLogger.info('GroqSpeechSynthesisService: Received WAV bytes (${bytes.length} bytes). Header: $headerHex');
        }

        // Patch streaming WAV header sizes for Android native MediaPlayer:
        if (bytes.length >= 44 &&
            bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
          final dataSize = bytes.length - 44;
          final riffSize = bytes.length - 8;
          
          final ByteData bd = ByteData.sublistView(bytes);
          bd.setUint32(4, riffSize, Endian.little);
          bd.setUint32(40, dataSize, Endian.little);
          appLogger.info('GroqSpeechSynthesisService: Patched WAV RIFF header (dataSize: $dataSize bytes)');
        }

        // Save the audio bytes to cache file
        await cacheFile.writeAsBytes(bytes);
        appLogger.info('GroqSpeechSynthesisService: Synthesis success, saved cache file: ${cacheFile.path}');
        return cacheFile.path;
      } else {
        appLogger.error('GroqSpeechSynthesisService: API error (${response.statusCode}): ${response.body}');
        return _fallbackOffline(cleanText);
      }
    } catch (e, st) {
      appLogger.error('GroqSpeechSynthesisService: Network/API failure during synthesis, triggering offline fallback', e, st);
      return _fallbackOffline(cleanText);
    }
  }

  /// Triggered when the API is unreachable. Returns null to signal the system to fall back
  /// to simulated text-to-speech presentation.
  String? _fallbackOffline(String text) {
    appLogger.warning('GroqSpeechSynthesisService: Offline mode active. Speech playback is simulated.');
    return null;
  }
}
