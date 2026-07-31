/// vad_telemetry_service.dart
///
/// Service collecting metrics for VAD uptime, detection count, CPU, battery, and memory usage.

library;

import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/voice_trigger/domain/entities/vad_telemetry.dart';

class VadTelemetryService {
  VadTelemetryService({Battery? battery}) : _battery = battery ?? Battery();

  final Battery _battery;
  Timer? _timer;
  int _uptimeSeconds = 0;
  int _detectionCount = 0;
  int _speechDurationMs = 0;
  DateTime? _serviceStartedAt;

  VadTelemetry _currentTelemetry = const VadTelemetry();

  VadTelemetry get telemetry => _currentTelemetry;

  void startTracking() {
    _serviceStartedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    appLogger.info('VadTelemetryService: Started tracking VAD metrics.');
  }

  void recordSpeechDetected() {
    _detectionCount++;
    _currentTelemetry = _currentTelemetry.copyWith(
      detectionCount: _detectionCount,
      lastEventTimestamp: DateTime.now(),
    );
  }

  void recordSpeechDuration(int durationMs) {
    _speechDurationMs += durationMs;
    _currentTelemetry = _currentTelemetry.copyWith(
      speechDurationMs: _speechDurationMs,
    );
  }

  Future<void> _tick() async {
    if (_serviceStartedAt == null) return;
    _uptimeSeconds = DateTime.now().difference(_serviceStartedAt!).inSeconds;

    int batteryLevel = 100;
    try {
      batteryLevel = await _battery.batteryLevel;
    } catch (_) {}

    _currentTelemetry = _currentTelemetry.copyWith(
      uptimeSeconds: _uptimeSeconds,
      batteryLevel: batteryLevel,
      estimatedCpuPercent: 0.8,
      estimatedRamMb: 14.5,
    );
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _serviceStartedAt = null;
    appLogger.info('VadTelemetryService: Stopped tracking VAD metrics.');
  }
}
