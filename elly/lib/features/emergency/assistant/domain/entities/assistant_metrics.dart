/// assistant_metrics.dart
///
/// Performance and latency diagnostics model for ELLY Live Assistant.

library;

import 'package:equatable/equatable.dart';

class AssistantMetrics extends Equatable {
  const AssistantMetrics({
    this.sttLatencyMs = 0,
    this.llmLatencyMs = 0,
    this.ttsLatencyMs = 0,
    this.playbackLatencyMs = 0,
    this.endToEndLatencyMs = 0,
    this.conversationCount = 0,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.speechDurationSeconds = 0,
    this.safetyCategory = 'safe',
    this.ttsCacheHits = 0,
    this.lastTranscript = '',
    this.lastResponse = '',
  });

  final int sttLatencyMs;
  final int llmLatencyMs;
  final int ttsLatencyMs;
  final int playbackLatencyMs;
  final int endToEndLatencyMs;
  final int conversationCount;
  final int promptTokens;
  final int completionTokens;
  final int speechDurationSeconds;
  final String safetyCategory;
  final int ttsCacheHits;
  final String lastTranscript;
  final String lastResponse;

  AssistantMetrics copyWith({
    int? sttLatencyMs,
    int? llmLatencyMs,
    int? ttsLatencyMs,
    int? playbackLatencyMs,
    int? endToEndLatencyMs,
    int? conversationCount,
    int? promptTokens,
    int? completionTokens,
    int? speechDurationSeconds,
    String? safetyCategory,
    int? ttsCacheHits,
    String? lastTranscript,
    String? lastResponse,
  }) {
    return AssistantMetrics(
      sttLatencyMs: sttLatencyMs ?? this.sttLatencyMs,
      llmLatencyMs: llmLatencyMs ?? this.llmLatencyMs,
      ttsLatencyMs: ttsLatencyMs ?? this.ttsLatencyMs,
      playbackLatencyMs: playbackLatencyMs ?? this.playbackLatencyMs,
      endToEndLatencyMs: endToEndLatencyMs ?? this.endToEndLatencyMs,
      conversationCount: conversationCount ?? this.conversationCount,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      speechDurationSeconds: speechDurationSeconds ?? this.speechDurationSeconds,
      safetyCategory: safetyCategory ?? this.safetyCategory,
      ttsCacheHits: ttsCacheHits ?? this.ttsCacheHits,
      lastTranscript: lastTranscript ?? this.lastTranscript,
      lastResponse: lastResponse ?? this.lastResponse,
    );
  }

  @override
  List<Object?> get props => [
        sttLatencyMs,
        llmLatencyMs,
        ttsLatencyMs,
        playbackLatencyMs,
        endToEndLatencyMs,
        conversationCount,
        promptTokens,
        completionTokens,
        speechDurationSeconds,
        safetyCategory,
        ttsCacheHits,
        lastTranscript,
        lastResponse,
      ];
}
