/// emergency_platform_events.dart
///
/// Strongly typed sealed event hierarchy for EmergencyEventBus compile-time safety.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/sos/domain/entities/confirmation_state.dart';

@immutable
sealed class EmergencyPlatformEvent {
  const EmergencyPlatformEvent({
    required this.eventId,
    required this.timestamp,
  });

  final String eventId;
  final DateTime timestamp;

  Map<String, dynamic> toJson();
}

class SafeConfirmedPlatformEvent extends EmergencyPlatformEvent {
  const SafeConfirmedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.result,
  });

  final ConfirmationResult result;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'SafeConfirmed',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'result': result.toJson(),
      };
}

class EmergencyConfirmedPlatformEvent extends EmergencyPlatformEvent {
  const EmergencyConfirmedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.result,
  });

  final ConfirmationResult result;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'EmergencyConfirmed',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'result': result.toJson(),
      };
}

class ConfirmationTimeoutPlatformEvent extends EmergencyPlatformEvent {
  const ConfirmationTimeoutPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.result,
  });

  final ConfirmationResult result;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ConfirmationTimeout',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'result': result.toJson(),
      };
}

class HighRiskBypassedPlatformEvent extends EmergencyPlatformEvent {
  const HighRiskBypassedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.reason,
  });

  final String reason;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'HighRiskBypassed',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
      };
}

class EmergencyPacketGeneratedPlatformEvent extends EmergencyPlatformEvent {
  const EmergencyPacketGeneratedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.packetId,
    required this.sessionId,
  });

  final String packetId;
  final String sessionId;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'EmergencyPacketGenerated',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'packetId': packetId,
        'sessionId': sessionId,
      };
}

class EmergencyPacketUpdatedPlatformEvent extends EmergencyPlatformEvent {
  const EmergencyPacketUpdatedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.packetId,
    required this.sessionId,
  });

  final String packetId;
  final String sessionId;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'EmergencyPacketUpdated',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'packetId': packetId,
        'sessionId': sessionId,
      };
}

class OfflineModeEnteredPlatformEvent extends EmergencyPlatformEvent {
  const OfflineModeEnteredPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.connectivityState,
  });

  final String connectivityState;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'OfflineModeEntered',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'connectivityState': connectivityState,
      };
}

class ConnectivityRestoredPlatformEvent extends EmergencyPlatformEvent {
  const ConnectivityRestoredPlatformEvent({
    required super.eventId,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ConnectivityRestored',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
      };
}

class PacketQueuedPlatformEvent extends EmergencyPlatformEvent {
  const PacketQueuedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.queueId,
    required this.packetId,
  });

  final String queueId;
  final String packetId;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PacketQueued',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'queueId': queueId,
        'packetId': packetId,
      };
}

class PacketUploadedPlatformEvent extends EmergencyPlatformEvent {
  const PacketUploadedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.packetId,
    required this.checksum,
  });

  final String packetId;
  final String checksum;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PacketUploaded',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'packetId': packetId,
        'checksum': checksum,
      };
}

class SynchronizationStartedPlatformEvent extends EmergencyPlatformEvent {
  const SynchronizationStartedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.queuedCount,
  });

  final int queuedCount;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'SynchronizationStarted',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'queuedCount': queuedCount,
      };
}

class SynchronizationCompletedPlatformEvent extends EmergencyPlatformEvent {
  const SynchronizationCompletedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.uploadedCount,
  });

  final int uploadedCount;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'SynchronizationCompleted',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'uploadedCount': uploadedCount,
      };
}

class SynchronizationFailedPlatformEvent extends EmergencyPlatformEvent {
  const SynchronizationFailedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.reason,
  });

  final String reason;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'SynchronizationFailed',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
      };
}

class PacketSchedulerStartedPlatformEvent extends EmergencyPlatformEvent {
  const PacketSchedulerStartedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.initialIntervalSeconds,
  });

  final int initialIntervalSeconds;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PacketSchedulerStarted',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'initialIntervalSeconds': initialIntervalSeconds,
      };
}

class PacketSchedulerStoppedPlatformEvent extends EmergencyPlatformEvent {
  const PacketSchedulerStoppedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.totalGenerated,
  });

  final int totalGenerated;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PacketSchedulerStopped',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'totalGenerated': totalGenerated,
      };
}

class PacketGeneratedPlatformEvent extends EmergencyPlatformEvent {
  const PacketGeneratedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.packetId,
    required this.sequenceNumber,
    required this.isDelta,
    required this.triggerReason,
  });

  final String packetId;
  final int sequenceNumber;
  final bool isDelta;
  final String triggerReason;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PacketGenerated',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'packetId': packetId,
        'sequenceNumber': sequenceNumber,
        'isDelta': isDelta,
        'triggerReason': triggerReason,
      };
}

class PacketSkippedPlatformEvent extends EmergencyPlatformEvent {
  const PacketSkippedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.reason,
  });

  final String reason;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PacketSkipped',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
      };
}

class PacketGenerationFailedPlatformEvent extends EmergencyPlatformEvent {
  const PacketGenerationFailedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.reason,
  });

  final String reason;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PacketGenerationFailed',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
      };
}

class PacketIntervalChangedPlatformEvent extends EmergencyPlatformEvent {
  const PacketIntervalChangedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.oldIntervalSeconds,
    required this.newIntervalSeconds,
    required this.reason,
  });

  final int oldIntervalSeconds;
  final int newIntervalSeconds;
  final String reason;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PacketIntervalChanged',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'oldIntervalSeconds': oldIntervalSeconds,
        'newIntervalSeconds': newIntervalSeconds,
        'reason': reason,
      };
}

class CountryDetectedPlatformEvent extends EmergencyPlatformEvent {
  const CountryDetectedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.countryCode,
    required this.detectionSource,
  });

  final String countryCode;
  final String detectionSource;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'CountryDetected',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'countryCode': countryCode,
        'detectionSource': detectionSource,
      };
}

class CountryChangedPlatformEvent extends EmergencyPlatformEvent {
  const CountryChangedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.oldCountryCode,
    required this.newCountryCode,
  });

  final String oldCountryCode;
  final String newCountryCode;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'CountryChanged',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'oldCountryCode': oldCountryCode,
        'newCountryCode': newCountryCode,
      };
}

class RoamingDetectedPlatformEvent extends EmergencyPlatformEvent {
  const RoamingDetectedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.countryCode,
  });

  final String countryCode;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'RoamingDetected',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'countryCode': countryCode,
      };
}

class EmergencyDirectoryUpdatedPlatformEvent extends EmergencyPlatformEvent {
  const EmergencyDirectoryUpdatedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.version,
  });

  final String version;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'EmergencyDirectoryUpdated',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
      };
}

class LocalizationChangedPlatformEvent extends EmergencyPlatformEvent {
  const LocalizationChangedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.locale,
  });

  final String locale;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'LocalizationChanged',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'locale': locale,
      };
}

class QueueRecoveredPlatformEvent extends EmergencyPlatformEvent {
  const QueueRecoveredPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.recoveredCount,
  });

  final int recoveredCount;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'QueueRecovered',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'recoveredCount': recoveredCount,
      };
}

class QueueCorruptedPlatformEvent extends EmergencyPlatformEvent {
  const QueueCorruptedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.corruptedCount,
  });

  final int corruptedCount;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'QueueCorrupted',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'corruptedCount': corruptedCount,
      };
}

class StorageLowPlatformEvent extends EmergencyPlatformEvent {
  const StorageLowPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.availableBytes,
  });

  final int availableBytes;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'StorageLow',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'availableBytes': availableBytes,
      };
}

class StorageCriticalPlatformEvent extends EmergencyPlatformEvent {
  const StorageCriticalPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.availableBytes,
  });

  final int availableBytes;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'StorageCritical',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'availableBytes': availableBytes,
      };
}

class BatteryPolicyChangedPlatformEvent extends EmergencyPlatformEvent {
  const BatteryPolicyChangedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.newPolicy,
  });

  final String newPolicy;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'BatteryPolicyChanged',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'newPolicy': newPolicy,
      };
}

class OfflineRecoveryCompletedPlatformEvent extends EmergencyPlatformEvent {
  const OfflineRecoveryCompletedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.recoveredCount,
  });

  final int recoveredCount;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'OfflineRecoveryCompleted',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'recoveredCount': recoveredCount,
      };
}

class OfflineRecoveryFailedPlatformEvent extends EmergencyPlatformEvent {
  const OfflineRecoveryFailedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.reason,
  });

  final String reason;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'OfflineRecoveryFailed',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
      };
}

class EmergencyReadinessEvaluatedPlatformEvent extends EmergencyPlatformEvent {
  const EmergencyReadinessEvaluatedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.score,
    required this.level,
  });

  final int score;
  final String level;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'EmergencyReadinessEvaluated',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'score': score,
        'level': level,
      };
}



class CommunicationRequestedPlatformEvent extends EmergencyPlatformEvent {
  const CommunicationRequestedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.requestId,
    required this.recipient,
  });

  final String requestId;
  final String recipient;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'CommunicationRequested',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'requestId': requestId,
        'recipient': recipient,
      };
}

class CommunicationSucceededPlatformEvent extends EmergencyPlatformEvent {
  const CommunicationSucceededPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.requestId,
    required this.channelUsed,
  });

  final String requestId;
  final String channelUsed;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'CommunicationSucceeded',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'requestId': requestId,
        'channelUsed': channelUsed,
      };
}

class CommunicationFailedPlatformEvent extends EmergencyPlatformEvent {
  const CommunicationFailedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.requestId,
    required this.reason,
  });

  final String requestId;
  final String reason;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'CommunicationFailed',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'requestId': requestId,
        'reason': reason,
      };
}

class EmergencyEscalatedPlatformEvent extends EmergencyPlatformEvent {
  const EmergencyEscalatedPlatformEvent({
    required super.eventId,
    required super.timestamp,
    required this.reason,
  });

  final String reason;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'EmergencyEscalated',
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
      };
}
