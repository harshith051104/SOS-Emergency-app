/// readiness_controller.dart
///
/// StateNotifier controller managing live ReadinessReport updates.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/readiness/domain/entities/readiness_report.dart';
import 'package:elly/features/emergency/readiness/domain/services/emergency_readiness_engine.dart';

class ReadinessController extends StateNotifier<ReadinessReport> {
  ReadinessController(this._engine) : super(_engine.evaluateReadiness());

  final EmergencyReadinessEngine _engine;

  void refreshReadiness() {
    state = _engine.evaluateReadiness();
  }
}
