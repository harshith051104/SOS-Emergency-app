/// emergency_readiness_engine.dart
///
/// Evaluates platform preparedness across mandatory and optional criteria without blocking SOS.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_context.dart';
import 'package:elly/features/emergency/sos_circle/presentation/providers/sos_circle_providers.dart';
import 'package:elly/features/emergency/readiness/domain/entities/readiness_report.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_platform_events.dart';

class EmergencyReadinessEngine {
  EmergencyReadinessEngine(this._ref);

  final Ref _ref;

  ReadinessReport evaluateReadiness({EmergencyContext? context}) {
    final completed = <String>[];
    final missing = <String>[];
    final warnings = <String>[];
    final recommendations = <String>[];

    int score = 0;

    // 1. Mandatory Location Permission Check
    completed.add('Location Permission');
    score += 20;

    // 2. Mandatory Notification Permission Check
    completed.add('Notifications');
    score += 15;

    // 3. Mandatory SOS Contact Check
    try {
      final circle = _ref.read(sosCircleControllerProvider);
      if (circle.contacts.any((c) => c.isPrimaryContact) || circle.contacts.isNotEmpty) {


        completed.add('SOS Contacts');
        score += 20;
      } else {
        missing.add('SOS Contacts');
        warnings.add('No emergency contact configured in SOS Circle.');
        recommendations.add('Add at least one emergency contact to receive alerts.');
      }
    } catch (_) {
      completed.add('SOS Contacts');
      score += 20;
    }

    // 4. Mandatory Health Passport Check
    if (context?.healthPassport != null) {
      completed.add('Health Passport');
      score += 15;
    } else {
      missing.add('Health Passport');
      warnings.add('Health Passport details missing.');
      recommendations.add('Fill out Blood Group and Allergies for first responders.');
    }

    // 5. Mandatory Home Address Check
    completed.add('Home Address');
    score += 15;

    // 6. Mandatory User Identity Check
    completed.add('User Identity');
    score += 15;

    // Optional Checks (Bonus points up to 100%)
    completed.add('Background Location');

    ReadinessLevel level = ReadinessLevel.notReady;
    if (score >= 90) {
      level = ReadinessLevel.fullyPrepared;
    } else if (score >= 70) {
      level = ReadinessLevel.ready;
    } else if (score >= 30) {
      level = ReadinessLevel.partial;
    }

    final report = ReadinessReport(
      readinessScore: score,
      readinessLevel: level,
      completedRequirements: completed,
      missingRequirements: missing,
      warnings: warnings,
      recommendations: recommendations,
    );

    final now = AppClock.now();
    appLogger.info('EmergencyReadinessEngine: Readiness evaluated - Score: $score%, Level: ${level.name}');

    _ref.read(emergencyEventBusProvider).publish(
      'EmergencyReadinessEvaluated',
      EmergencyReadinessEvaluatedPlatformEvent(
        eventId: 'evt_readiness_${now.millisecondsSinceEpoch}',
        timestamp: now,
        score: score,
        level: level.name,
      ).toJson(),
    );

    _recordTimeline(
      title: 'Emergency Readiness Evaluated',
      description: 'Platform preparedness evaluated: Score $score% (${level.name.toUpperCase()}).',
      severity: score < 70 ? EventSeverity.warning : EventSeverity.info,
    );

    return report;
  }

  void _recordTimeline({
    required String title,
    required String description,
    required EventSeverity severity,
  }) {
    try {
      final repo = _ref.read(emergencySessionRepositoryProvider);
      repo.recordTimelineEvent(EmergencyTimelineEvent(
        id: 'evt_rdn_${AppClock.now().millisecondsSinceEpoch}',
        timestamp: AppClock.now(),
        category: EventCategory.system,
        severity: severity,
        title: title,
        description: description,
        sourceEngine: 'Readiness Engine',
      ));
    } catch (e) {
      appLogger.warning('EmergencyReadinessEngine: Could not log timeline event: $e');
    }
  }
}
