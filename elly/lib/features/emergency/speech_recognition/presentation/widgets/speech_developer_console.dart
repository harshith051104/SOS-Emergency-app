/// speech_developer_console.dart
///
/// Developer diagnostics widget for monitoring STT engine status, active transcripts,
/// inference latency, and cancellation controls.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_config.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_state.dart';
import 'package:elly/features/emergency/speech_recognition/presentation/providers/speech_providers.dart';

class SpeechDeveloperConsole extends ConsumerWidget {
  const SpeechDeveloperConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(speechControllerProvider);
    final telemetry = ref.watch(speechTelemetryProvider);
    final config = ref.watch(speechConfigProvider);

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.record_voice_over, color: AppColors.sosPrimary, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Speech Recognition (STT)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(speechState.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(speechState.status)),
                  ),
                  child: Text(
                    speechState.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(speechState.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Engine Model', config.engine == SpeechEngine.sherpaSenseVoice
                ? 'Sherpa-ONNX SenseVoice CTC (Backend)'
                : config.engine == SpeechEngine.whisper
                    ? 'Groq Whisper v3 Turbo (Cloud)'
                    : 'Mock STT'),
            _buildInfoRow('Active Session', speechState.activeSessionId ?? 'None'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: speechState.lastTranscript != null && speechState.lastTranscript!.isNotEmpty
                      ? Colors.amberAccent
                      : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.record_voice_over, color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE TRANSCRIPT:',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    speechState.lastTranscript != null && speechState.lastTranscript!.isNotEmpty
                        ? '"${speechState.lastTranscript}"'
                        : '🎤 Speak into microphone... Listening for speech utterance...',
                    style: TextStyle(
                      color: speechState.lastTranscript != null && speechState.lastTranscript!.isNotEmpty
                          ? Colors.white
                          : Colors.white54,
                      fontSize: 14,
                      fontWeight: speechState.lastTranscript != null && speechState.lastTranscript!.isNotEmpty
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontStyle: speechState.lastTranscript != null && speechState.lastTranscript!.isNotEmpty
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (speechState.confidence > 0)
              _buildInfoRow('Confidence', '${(speechState.confidence * 100).toStringAsFixed(1)}%'),
            if (speechState.lastInferenceTimeMs > 0)
              _buildInfoRow('Inference Latency', '${speechState.lastInferenceTimeMs} ms'),
            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completed: ${telemetry.recognitionsCompleted} | Avg: ${telemetry.averageInferenceTimeMs}ms',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (speechState.status == SpeechStatus.transcribing || speechState.status == SpeechStatus.buffering)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    onPressed: () {
                      ref.read(speechControllerProvider.notifier).cancelActiveTranscription();
                    },
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel STT'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SpeechStatus status) {
    switch (status) {
      case SpeechStatus.idle:
        return Colors.grey;
      case SpeechStatus.listening:
        return Colors.blue;
      case SpeechStatus.buffering:
        return Colors.orange;
      case SpeechStatus.transcribing:
        return Colors.amber;
      case SpeechStatus.completed:
        return Colors.green;
      case SpeechStatus.cancelled:
        return Colors.purpleAccent;
      case SpeechStatus.error:
        return Colors.redAccent;
    }
  }
}
