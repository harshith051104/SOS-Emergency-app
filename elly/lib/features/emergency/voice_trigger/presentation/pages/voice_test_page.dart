/// voice_test_page.dart
///
/// Standalone Voice & Microphone Diagnostic Test Console.
/// Real-time live PCM peak amplitude visualizer, Silero ONNX speech probability meter,
/// customizable hardware threshold sliders, and real-time audio log stream.

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_state.dart';
import 'package:elly/features/emergency/voice_trigger/presentation/providers/vad_providers.dart';
import 'package:elly/features/emergency/speech_recognition/presentation/providers/speech_providers.dart';
import 'package:elly/features/emergency/intent_detection/presentation/providers/intent_providers.dart';
import 'package:elly/features/emergency/decision_engine/presentation/providers/decision_providers.dart';
import 'package:elly/features/emergency/voice_trigger/data/channels/vad_platform_channel.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';

class VoiceTestPage extends ConsumerStatefulWidget {
  const VoiceTestPage({super.key});

  @override
  ConsumerState<VoiceTestPage> createState() => _VoiceTestPageState();
}

class _VoiceTestPageState extends ConsumerState<VoiceTestPage> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _nativeStreamSub;
  
  double _peakAmplitude = 0;
  double _rmsEnergy = 0;
  double _onnxProbability = 0;
  double _latencyMs = 0;

  @override
  void initState() {
    super.initState();
    _addLog('🎙️ Voice Test Console Initialized');
    _listenToNativeChannel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Eagerly instantiate all downstream emergency pipeline controllers
      ref.read(speechControllerProvider);
      ref.read(intentControllerProvider);
      ref.read(decisionControllerProvider);
    });
  }

  @override
  void dispose() {
    _nativeStreamSub?.cancel();
    super.dispose();
  }

  void _listenToNativeChannel() {
    const channel = VadPlatformChannel();
    if (!channel.isSupported) return;

    _nativeStreamSub = channel.vadEventStream().listen((data) {
      final event = data['event'] as String?;
      if (event == 'vadTelemetryUpdate') {
        final maxAmp = (data['maxAmplitude'] as num?)?.toInt() ?? 0;
        final rms = (data['rms'] as num?)?.toDouble() ?? 0.0;
        final prob = (data['probability'] as num?)?.toDouble() ?? 0.0;
        final readSize = (data['readSize'] as num?)?.toInt() ?? 0;
        final isSpeech = (data['isSpeechFrame'] as bool?) ?? false;

        setState(() {
          _peakAmplitude = maxAmp.toDouble();
          _rmsEnergy = rms;
          _onnxProbability = prob;
        });

        final statusStr = maxAmp == 0 
            ? '⚠️ MIC SILENT (MaxAmp=0)' 
            : (isSpeech ? '🗣️ SPEECH' : '🤫 SILENCE');
        _addLog('[PCM] Read:$readSize | MaxAmp:$maxAmp | RMS:${rms.toStringAsFixed(4)} | Prob:${(prob * 100).toStringAsFixed(1)}% | $statusStr');
      } else if (event == 'speechDetected') {
        _addLog('🗣️ NATIVE EVENT: SPEECH DETECTED!');
        final bus = ref.read(emergencyEventBusProvider);
        bus.publish('SpeechDetected', {'timestamp': DateTime.now().toIso8601String()});
      } else if (event == 'speechEnded') {
        _addLog('🔇 NATIVE EVENT: SPEECH ENDED');
        final bus = ref.read(emergencyEventBusProvider);
        bus.publish('SpeechEnded', {'timestamp': DateTime.now().toIso8601String()});
      } else if (event == 'error') {
        _addLog('❌ NATIVE ERROR: ${data['message']}');
      }
    });
  }

  void _addLog(String message) {
    if (!mounted) return;
    final timeStr = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.add('[$timeStr] $message');
      if (_logs.length > 100) _logs.removeAt(0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final vadState = ref.watch(vadControllerProvider);
    final speechState = ref.watch(speechControllerProvider);
    final intentState = ref.watch(intentControllerProvider);
    final decisionState = ref.watch(decisionControllerProvider);

    final isListening = vadState.status == VadStatus.listening || vadState.status == VadStatus.speechDetected;
    final isSpeechDetected = vadState.status == VadStatus.speechDetected;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '🎙️ Standalone Voice Tester',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Logs',
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Live Status Banner ──────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSpeechDetected
                      ? Colors.amber.withValues(alpha: 0.2)
                      : (isListening ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSpeechDetected ? Colors.amber : (isListening ? Colors.green : Colors.red),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSpeechDetected ? Icons.record_voice_over : (isListening ? Icons.mic : Icons.mic_off),
                      size: 32,
                      color: isSpeechDetected ? Colors.amber : (isListening ? Colors.green : Colors.red),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSpeechDetected ? '🗣️ SPEECH DETECTED!' : (isListening ? '👂 LISTENING TO MIC...' : '🔴 VAD SERVICE STOPPED'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSpeechDetected ? Colors.amber : (isListening ? Colors.green : Colors.red),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isListening ? 'Speak naturally into your device microphone' : 'Tap button below to start background listening',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 2. Real-Time Gauges & VU Meter ─────────────────────────────
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Acoustic Signals (Silero VAD ONNX)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      
                      // Microphone Hardware Peak Amplitude VU Meter
                      Row(
                        children: [
                          const SizedBox(width: 120, child: Text('Mic Hardware Amp:', style: TextStyle(color: Colors.white70, fontSize: 12))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (_peakAmplitude / 5000.0).clamp(0.0, 1.0),
                                minHeight: 12,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _peakAmplitude > 0 ? Colors.greenAccent : Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _peakAmplitude.toInt().toString(),
                            style: TextStyle(
                              color: _peakAmplitude > 0 ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Silero ONNX Speech Probability Gauge
                      Row(
                        children: [
                          const SizedBox(width: 120, child: Text('ONNX Probability:', style: TextStyle(color: Colors.white70, fontSize: 12))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: vadState.speechProbability.clamp(0.0, 1.0),
                                minHeight: 12,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vadState.speechProbability >= 0.35 ? Colors.amber : Colors.cyanAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(vadState.speechProbability * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),

                      // Pipeline Stage Outputs
                      _buildStageBadge('1. Voice Activity', isSpeechDetected ? 'VOICE DETECTED' : 'SILENCE', isSpeechDetected),
                      _buildStageBadge('2. Speech Transcript', (speechState.lastTranscript?.isNotEmpty ?? false) ? speechState.lastTranscript! : 'Awaiting speech...', (speechState.lastTranscript?.isNotEmpty ?? false)),
                      _buildStageBadge('3. Intent Classifier', intentState.lastResult != null ? intentState.lastResult!.intent.name.toUpperCase() : 'Idle', intentState.lastResult != null),
                      _buildStageBadge('4. Emergency Decision', decisionState.lastResult != null ? '${decisionState.lastResult!.recommendation.name.toUpperCase()} (${(decisionState.lastResult!.emergencyConfidence * 100).toInt()}%)' : 'Idle', decisionState.lastResult != null),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Control Buttons ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isListening ? Colors.redAccent : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final notifier = ref.read(vadControllerProvider.notifier);
                        if (isListening) {
                          notifier.stopVadService();
                          _addLog('⏹ Stopped VAD Protection Service');
                        } else {
                          notifier.startVadService();
                          _addLog('▶ Started VAD Protection Service');
                        }
                      },
                      icon: Icon(isListening ? Icons.stop : Icons.play_arrow),
                      label: Text(isListening ? 'STOP SERVICE' : 'START SERVICE', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amberAccent,
                        side: const BorderSide(color: Colors.amberAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _addLog('⚡ Injecting Synthetic "Help Emergency!" Trigger');
                        final bus = ref.read(emergencyEventBusProvider);
                        bus.publish('SpeechDetected', {'timestamp': DateTime.now().toIso8601String()});
                        Future.delayed(const Duration(milliseconds: 800), () {
                          bus.publish('SpeechEnded', {'timestamp': DateTime.now().toIso8601String()});
                        });
                      },
                      icon: const Icon(Icons.bolt),
                      label: const Text('TEST TRIGGER', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── 4. Live Event Log Terminal ──────────────────────────────────
              const Text(
                'Live Diagnostic Event Stream',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: Colors.greenAccent,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageBadge(String stageName, String value, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(stageName, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: active ? Colors.cyan.withValues(alpha: 0.2) : Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: active ? Colors.cyanAccent : Colors.white38,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
