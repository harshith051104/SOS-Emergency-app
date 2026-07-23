/// assistant_brain.dart
///
/// Implements decision-making logic, event deduplication, and battery threshold checks
/// for system voice announcements.

library;

import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/voice_event.dart';
import 'conversation_policy_engine.dart';
import 'voice_scheduler.dart';

class AssistantBrain {
  AssistantBrain({
    required ConversationPolicyEngine policyEngine,
    required VoiceScheduler scheduler,
  })  : _policyEngine = policyEngine,
        _scheduler = scheduler;

  final ConversationPolicyEngine _policyEngine;
  final VoiceScheduler _scheduler;

  // Deduplication state variables
  DateTime? _lastLocationTime;
  String? _lastLocationAddress;
  int? _lastBatteryThreshold;
  final Set<String> _spokenSystemUpdates = {};

  /// Decides if a battery change should trigger a spoken alert.
  /// Spoken only when crossing 20%, 10%, and 5% thresholds.
  void processBatteryUpdate(int level) {
    int? threshold;
    if (level <= 5) {
      threshold = 5;
    } else if (level <= 10) {
      threshold = 10;
    } else if (level <= 20) {
      threshold = 20;
    }

    if (threshold != null && threshold != _lastBatteryThreshold) {
      _lastBatteryThreshold = threshold;
      appLogger.info('AssistantBrain: Battery alert triggered for threshold: $threshold%');
      
      _scheduler.queueEvent(VoiceEvent(
        id: 'battery_warning_$threshold',
        text: 'Your battery is extremely low at $level percent. Please connect a charger if possible.',
        priority: VoicePriority.critical,
        timestamp: DateTime.now(),
        isInterrupting: true,
      ));
    }
  }

  /// Decides if a location change should trigger a spoken announcement.
  /// Merges address changes and suppresses rapid duplicates within 15 seconds.
  void processLocationUpdate({required String address, required String accuracy}) {
    final now = DateTime.now();
    
    // Skip if address is unavailable/error
    if (address.toLowerCase().contains('unavailable') || address.toLowerCase().contains('denied')) {
      return;
    }

    // Deduplicate identical address or rapid updates within 15 seconds
    if (_lastLocationAddress == address) return;
    if (_lastLocationTime != null && now.difference(_lastLocationTime!) < const Duration(seconds: 15)) {
      return;
    }

    _lastLocationTime = now;
    _lastLocationAddress = address;
    appLogger.info('AssistantBrain: Location update alert queued: $address');

    _scheduler.queueEvent(VoiceEvent(
      id: 'location_update_${now.millisecondsSinceEpoch}',
      text: 'I have updated your location.',
      priority: VoicePriority.standard,
      timestamp: now,
    ));
  }

  /// Decides if a GPS lost event should trigger a warning.
  void processGpsLost() {
    final eventId = 'gps_lost_warning';
    if (_spokenSystemUpdates.contains(eventId)) return;

    _spokenSystemUpdates.add(eventId);
    appLogger.info('AssistantBrain: GPS lost alert queued.');

    _scheduler.queueEvent(VoiceEvent(
      id: eventId,
      text: 'I have lost GPS signal. Please move to an open area if safe.',
      priority: VoicePriority.critical,
      timestamp: DateTime.now(),
      isInterrupting: true,
    ));
  }

  /// Decides if a data packet completion event should trigger a spoken notification.
  void processPacketCompleted() {
    final eventId = 'packet_compiled_announcement';
    if (_spokenSystemUpdates.contains(eventId)) return;

    _spokenSystemUpdates.add(eventId);
    appLogger.info('AssistantBrain: Packet completed alert queued.');

    _scheduler.queueEvent(VoiceEvent(
      id: eventId,
      text: 'Your emergency safety packet has been compiled.',
      priority: VoicePriority.standard,
      timestamp: DateTime.now(),
    ));
  }

  /// Resets the brain state (useful on session restart/re-activation).
  void reset() {
    _lastLocationTime = null;
    _lastLocationAddress = null;
    _lastBatteryThreshold = null;
    _spokenSystemUpdates.clear();
  }
}
