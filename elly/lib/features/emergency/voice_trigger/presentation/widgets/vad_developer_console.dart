/// vad_developer_console.dart
///
/// Developer diagnostics widget for monitoring Phase 1 Voice Activity Detection (VAD),
/// status bar foreground service, speech presence detection, live microphone controls,
/// and pipeline simulation.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_state.dart';
import 'package:elly/features/emergency/voice_trigger/presentation/providers/vad_providers.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';

class VadDeveloperConsole extends ConsumerWidget {
  const VadDeveloperConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vadState = ref.watch(vadControllerProvider);
    final telemetry = ref.watch(vadTelemetryProvider);
    final config = ref.watch(vadConfigProvider);

    final isRunning = vadState.status == VadStatus.listening || vadState.status == VadStatus.speechDetected;

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
                const Icon(Icons.mic, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Phase 1 — Voice Protection (VAD)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(vadState.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(vadState.status)),
                  ),
                  child: Text(
                    vadState.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(vadState.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Audio Engine', 'Silero VAD (16kHz Mono PCM)'),
            _buildInfoRow('Foreground Service', isRunning ? 'Active (Status Notification)' : 'Stopped (Tap button below)'),
            _buildInfoRow(
              'Speech Status',
              vadState.status == VadStatus.speechDetected ? '🗣️ SPEECH DETECTED' : '🤫 SILENCE',
              highlightColor: vadState.status == VadStatus.speechDetected ? Colors.amberAccent : null,
            ),
            _buildInfoRow('Sensitivity Thresh', '${(config.speechThreshold * 100).toInt()}%'),
            const SizedBox(height: 12),
            
            // Full Width Primary Action Button for Starting / Stopping Service
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning ? Colors.redAccent : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final controller = ref.read(vadControllerProvider.notifier);
                  if (isRunning) {
                    controller.stopVadService();
                  } else {
                    controller.startVadService();
                  }
                },
                icon: Icon(isRunning ? Icons.stop : Icons.play_arrow, size: 20),
                label: Text(
                  isRunning ? 'STOP VAD PROTECTION SERVICE' : '▶ START VOICE PROTECTION SERVICE',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Simulation Button for Quick Pipeline Testing
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amberAccent,
                  side: const BorderSide(color: Colors.amberAccent),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _simulateSpeechPipeline(ref),
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text(
                  '⚡ SIMULATE TEST SPEECH (PHASE 1 ➔ 2 ➔ 3 ➔ 4 ➔ 5 ➔ 6 ➔ 7 ➔ 8)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),

            const Divider(color: Colors.white10, height: 20),
            Text(
              'Uptime: ${telemetry.uptimeSeconds}s | Battery: ${telemetry.batteryLevel}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateSpeechPipeline(WidgetRef ref) async {
    final eventBus = ref.read(emergencyEventBusProvider);
    final now = DateTime.now();

    // 1. Fire SpeechDetected event
    eventBus.publish('SpeechDetected', {
      'timestamp': now.toIso8601String(),
    });

    // 2. Wait 1 second to simulate speech duration
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    // 3. Fire SpeechEnded event
    eventBus.publish('SpeechEnded', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Widget _buildInfoRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlightColor ?? Colors.white,
                fontSize: 12,
                fontWeight: highlightColor != null ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(VadStatus status) {
    switch (status) {
      case VadStatus.idle:
      case VadStatus.stopped:
        return Colors.grey;
      case VadStatus.starting:
        return Colors.blue;
      case VadStatus.listening:
        return Colors.cyanAccent;
      case VadStatus.speechDetected:
        return Colors.amberAccent;
      case VadStatus.paused:
        return Colors.purpleAccent;
      case VadStatus.error:
      case VadStatus.unsupported:
        return Colors.redAccent;
    }
  }
}
