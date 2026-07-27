/// monitoring_watchdog.dart
///
/// Service monitoring execution heartbeat to detect silent background failures and trigger recovery.

library;

import 'dart:async';
import 'package:flutter/foundation.dart';

class MonitoringWatchdog {
  MonitoringWatchdog({
    required this.onStallDetected,
    this.maxStallMultiplier = 2.5,
  });

  final Future<void> Function() onStallDetected;
  final double maxStallMultiplier;

  Timer? _watchdogTimer;
  DateTime? _lastHeartbeat;
  Duration _expectedInterval = const Duration(seconds: 10);
  bool _isWatchdogActive = false;

  bool get isActive => _isWatchdogActive;
  DateTime? get lastHeartbeat => _lastHeartbeat;

  /// Starts monitoring loop heartbeat.
  void startWatchdog(Duration expectedInterval) {
    _expectedInterval = expectedInterval;
    _lastHeartbeat = DateTime.now();
    _isWatchdogActive = true;

    _watchdogTimer?.cancel();
    final checkFrequency = Duration(milliseconds: (expectedInterval.inMilliseconds * 0.8).round());

    _watchdogTimer = Timer.periodic(checkFrequency, (_) {
      _checkHeartbeat();
    });
  }

  /// Records a successful monitoring cycle heartbeat.
  void pingHeartbeat() {
    _lastHeartbeat = DateTime.now();
  }

  /// Updates expected collection frequency interval.
  void updateInterval(Duration newInterval) {
    _expectedInterval = newInterval;
    if (_isWatchdogActive) {
      startWatchdog(newInterval);
    }
  }

  /// Stops watchdog.
  void stopWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _isWatchdogActive = false;
  }

  void _checkHeartbeat() {
    if (!_isWatchdogActive || _lastHeartbeat == null) return;

    final elapsedMs = DateTime.now().difference(_lastHeartbeat!).inMilliseconds;
    final maxAllowedMs = (_expectedInterval.inMilliseconds * maxStallMultiplier).round();

    if (elapsedMs > maxAllowedMs) {
      debugPrint('MonitoringWatchdog: Engine stall detected! Elapsed: ${elapsedMs}ms, Max Allowed: ${maxAllowedMs}ms');
      pingHeartbeat();
      onStallDetected();
    }
  }
}
