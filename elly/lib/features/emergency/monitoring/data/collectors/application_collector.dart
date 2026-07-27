/// application_collector.dart
///
/// Bounded timeout collector for app lifecycle state (foreground/background) & session metrics.

library;

import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../domain/entities/sensor_health.dart';
import '../../domain/entities/telemetry_snapshot.dart';
import 'base_collector.dart';

class ApplicationCollector
    extends BaseTelemetryCollector<ApplicationTelemetry> {
  ApplicationCollector({
    required this.sessionStartedAt,
    this.appVersion = '1.0.0',
  });

  final DateTime sessionStartedAt;
  final String appVersion;

  @override
  SensorType get sensorType => SensorType.application;

  @override
  Duration get defaultTimeoutBudget => const Duration(milliseconds: 100);

  @override
  Future<ApplicationTelemetry> collect({Duration? timeoutBudget}) async {
    final now = DateTime.now();
    final duration = now.difference(sessionStartedAt);

    bool isForeground = true;
    try {
      final state = WidgetsBinding.instance.lifecycleState;
      if (state != null) {
        isForeground = state == AppLifecycleState.resumed;
      }
    } catch (_) {}

    return ApplicationTelemetry(
      isForeground: isForeground,
      lastUserInteraction: now,
      sessionDuration: duration,
      appVersion: appVersion,
    );
  }
}
