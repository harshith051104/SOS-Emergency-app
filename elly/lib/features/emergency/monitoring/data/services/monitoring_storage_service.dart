/// monitoring_storage_service.dart
///
/// Encodes, calculates & verifies checksums (FNV-1a), quarantines corrupted packets, and persists monitoring state.

library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/packet_record.dart';
import '../../domain/entities/timeline_entry.dart';
import '../../domain/entities/session_metadata.dart';
import '../../domain/entities/telemetry_snapshot.dart';
import '../../domain/entities/telemetry_confidence.dart';
import '../../domain/entities/emergency_severity.dart';
import '../../domain/entities/retention_policy.dart';
import '../../domain/entities/session_integrity_report.dart';

class MonitoringStorageService {
  static const String _sessionMetaKey = 'elly_monitoring_active_session';
  static const String _packetPrefix = 'elly_packet_';
  static const String _timelinePrefix = 'elly_timeline_';
  static const String _sessionListKey = 'elly_sessions_list';

  /// Saves a generated packet record locally.
  Future<void> savePacket(PacketRecord packet) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_packetPrefix${packet.sessionId}_${packet.packetNumber}';
      final jsonMap = _packetToJson(packet);
      await prefs.setString(key, jsonEncode(jsonMap));
      await _registerSessionId(prefs, packet.sessionId);
    } catch (_) {}
  }

  /// Retrieves all saved packets for a session ID with Packet Integrity Verification.
  Future<List<PacketRecord>> getPackets(String sessionId, {bool skipCorrupted = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
          (k) => k.startsWith('$_packetPrefix${sessionId}_'));

      final list = <PacketRecord>[];
      for (final key in keys) {
        final str = prefs.getString(key);
        if (str != null) {
          try {
            final map = jsonDecode(str) as Map<String, dynamic>;
            final packet = _packetFromJson(map);

            // Re-verify payload integrity checksum
            final p = packet;
            final payloadForHash = '${p.sessionId}|${p.packetNumber}|${p.reasonCode}|${p.utcTime.toIso8601String()}|${p.telemetry.location.latitude},${p.telemetry.location.longitude}|${p.telemetry.device.batteryPercent}|${p.telemetry.confidence.overallConfidence}|${p.telemetry.severity.score}';
            final expectedChecksum = calculateFnv1aChecksum(payloadForHash);

            if (p.checksum != expectedChecksum) {
              debugPrint('MonitoringStorageService: QUARANTINE! Checksum mismatch on Packet #${p.packetNumber} for session $sessionId');
              if (!skipCorrupted) list.add(packet);
              continue;
            }

            list.add(packet);
          } catch (e) {
            debugPrint('MonitoringStorageService: Corrupted packet payload error: $e');
          }
        }
      }
      list.sort((a, b) => a.packetNumber.compareTo(b.packetNumber));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Generates a Session Integrity Report summarizing emergency session data metrics.
  Future<SessionIntegrityReport> generateSessionIntegrityReport(String sessionId) async {
    final validPackets = await getPackets(sessionId);
    final allRawKeysCount = (await _getRawPacketKeys(sessionId)).length;
    final corruptedCount = allRawKeysCount - validPackets.length;

    Duration duration = Duration.zero;

    if (validPackets.isNotEmpty) {
      duration = validPackets.last.localTime.difference(validPackets.first.localTime);
    }

    int totalConfidence = 0;
    int gpsAvailableCount = 0;
    int offlineCount = 0;
    String highestSev = 'LOW';
    int maxSevScore = 0;

    for (final p in validPackets) {
      totalConfidence += p.telemetry.confidence.overallConfidence;
      if (p.telemetry.location.hasValidCoordinates) gpsAvailableCount++;
      if (!p.telemetry.connectivity.isInternetAvailable) offlineCount++;

      if (p.telemetry.severity.score > maxSevScore) {
        maxSevScore = p.telemetry.severity.score;
        highestSev = p.telemetry.severity.level.name.toUpperCase();
      }
    }

    final avgConf = validPackets.isNotEmpty
        ? (totalConfidence / validPackets.length).round()
        : 0;
    final gpsPercent = validPackets.isNotEmpty
        ? (gpsAvailableCount / validPackets.length) * 100.0
        : 0.0;

    final offlineDuration = validPackets.isNotEmpty
        ? Duration(seconds: offlineCount * 10)
        : Duration.zero;

    return SessionIntegrityReport(
      sessionId: sessionId,
      sessionDuration: duration,
      totalPacketsGenerated: allRawKeysCount,
      packetsStored: validPackets.length,
      corruptedPacketsDetected: corruptedCount,
      offlineDuration: offlineDuration,
      gpsAvailabilityPercent: gpsPercent,
      averageConfidencePercent: avgConf,
      highestSeverityLevel: highestSev,
      finalizedAt: DateTime.now(),
    );
  }

  Future<List<String>> _getRawPacketKeys(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().where((k) => k.startsWith('$_packetPrefix${sessionId}_')).toList();
  }

  /// Appends a timeline entry locally.
  Future<void> saveTimelineEntry(String sessionId, TimelineEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_timelinePrefix$sessionId';
      final existing = prefs.getStringList(key) ?? [];
      final map = _timelineToJson(entry);
      existing.add(jsonEncode(map));
      await prefs.setStringList(key, existing);
    } catch (_) {}
  }

  /// Retrieves timeline entries for a session ID.
  Future<List<TimelineEntry>> getTimeline(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_timelinePrefix$sessionId';
      final list = prefs.getStringList(key) ?? [];
      return list.map((str) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return _timelineFromJson(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves active session metadata.
  Future<void> saveSessionMetadata(SessionMetadata metadata) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _sessionMetadataToJson(metadata);
      await prefs.setString(_sessionMetaKey, jsonEncode(map));
      await _registerSessionId(prefs, metadata.sessionId);
    } catch (_) {}
  }

  /// Retrieves active session metadata if present.
  Future<SessionMetadata?> getActiveSessionMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_sessionMetaKey);
      if (str == null) return null;
      final map = jsonDecode(str) as Map<String, dynamic>;
      return _sessionMetadataFromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clears active session metadata.
  Future<void> clearActiveSessionMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionMetaKey);
    } catch (_) {}
  }

  /// Applies retention policy to purge expired session data.
  Future<void> applyRetentionPolicy(RetentionPolicy policy) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionIds = prefs.getStringList(_sessionListKey) ?? [];
      final now = DateTime.now();

      final active = await getActiveSessionMetadata();
      final activeId = active?.sessionId;

      final remainingIds = <String>[];

      for (final sId in sessionIds) {
        if (sId == activeId) {
          remainingIds.add(sId);
          continue;
        }

        final timeline = await getTimeline(sId);
        if (timeline.isNotEmpty) {
          final lastEventTime = timeline.last.localTime;
          if (now.difference(lastEventTime) > policy.maxCompletedSessionAge) {
            await deleteSession(sId);
            continue;
          }
        }
        remainingIds.add(sId);
      }

      await prefs.setStringList(_sessionListKey, remainingIds);
    } catch (_) {}
  }

  /// Deletes all data for a specific session ID.
  Future<void> deleteSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('$_packetPrefix${sessionId}_') ||
            key == '$_timelinePrefix$sessionId') {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }

  /// High performance 32-bit FNV-1a checksum hash calculation (Web & Mobile compatible).
  String calculateFnv1aChecksum(String payload) {
    var hash = 0x811c9dc5;
    final bytes = utf8.encode(payload);
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  Future<void> _registerSessionId(SharedPreferences prefs, String sessionId) async {
    final list = prefs.getStringList(_sessionListKey) ?? [];
    if (!list.contains(sessionId)) {
      list.add(sessionId);
      await prefs.setStringList(_sessionListKey, list);
    }
  }

  Map<String, dynamic> _packetToJson(PacketRecord p) {
    return {
      'schemaVersion': p.schemaVersion,
      'packetNumber': p.packetNumber,
      'reasonCode': p.reasonCode,
      'sessionId': p.sessionId,
      'utcTime': p.utcTime.toIso8601String(),
      'localTime': p.localTime.toIso8601String(),
      'monotonicElapsedMs': p.monotonicElapsedMs,
      'sessionDurationMs': p.sessionDuration.inMilliseconds,
      'checksum': p.checksum,
      'telemetry': _telemetryToJson(p.telemetry),
    };
  }

  PacketRecord _packetFromJson(Map<String, dynamic> json) {
    return PacketRecord(
      schemaVersion: json['schemaVersion'] ?? '1.0',
      packetNumber: json['packetNumber'] as int,
      reasonCode: json['reasonCode'] as String,
      sessionId: json['sessionId'] as String,
      utcTime: DateTime.parse(json['utcTime'] as String),
      localTime: DateTime.parse(json['localTime'] as String),
      monotonicElapsedMs: json['monotonicElapsedMs'] as int,
      sessionDuration: Duration(milliseconds: json['sessionDurationMs'] as int),
      checksum: json['checksum'] as String,
      telemetry: _telemetryFromJson(json['telemetry'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> _telemetryToJson(TelemetrySnapshot t) {
    return {
      'utcTime': t.utcTime.toIso8601String(),
      'localTime': t.localTime.toIso8601String(),
      'monotonicElapsedMs': t.monotonicElapsedMs,
      'location': {
        'latitude': t.location.latitude,
        'longitude': t.location.longitude,
        'altitude': t.location.altitude,
        'accuracy': t.location.accuracy,
        'speed': t.location.speed,
        'heading': t.location.heading,
        'address': t.location.address,
        'timestamp': t.location.timestamp.toIso8601String(),
        'isGpsEnabled': t.location.isGpsEnabled,
        'isMockLocation': t.location.isMockLocation,
        'isoCountryCode': t.location.isoCountryCode,
      },
      'device': {
        'batteryPercent': t.device.batteryPercent,
        'isCharging': t.device.isCharging,
        'batteryTemperatureCelsius': t.device.batteryTemperatureCelsius,
        'isBatterySaverEnabled': t.device.isBatterySaverEnabled,
        'isScreenLocked': t.device.isScreenLocked,
        'deviceOrientation': t.device.deviceOrientation,
        'deviceName': t.device.deviceName,
        'osVersion': t.device.osVersion,
        'platform': t.device.platform,
        'timeZone': t.device.timeZone,
        'locale': t.device.locale,
      },
      'connectivity': {
        'isInternetAvailable': t.connectivity.isInternetAvailable,
        'connectionType': t.connectivity.connectionType,
        'isWifiEnabled': t.connectivity.isWifiEnabled,
        'isMobileDataEnabled': t.connectivity.isMobileDataEnabled,
        'isBluetoothEnabled': t.connectivity.isBluetoothEnabled,
        'isAirplaneModeEnabled': t.connectivity.isAirplaneModeEnabled,
        'signalStrengthDbm': t.connectivity.signalStrengthDbm,
      },
      'application': {
        'isForeground': t.application.isForeground,
        'lastUserInteraction': t.application.lastUserInteraction.toIso8601String(),
        'sessionDurationMs': t.application.sessionDuration.inMilliseconds,
        'appVersion': t.application.appVersion,
      },
      'motion': {
        'motionState': t.motion.motionState,
        'confidenceScore': t.motion.confidenceScore,
        'stepCount': t.motion.stepCount,
      },
      'health': {
        'heartRateBpm': t.health.heartRateBpm,
        'bloodOxygenPercent': t.health.bloodOxygenPercent,
        'systolicBloodPressure': t.health.systolicBloodPressure,
        'diastolicBloodPressure': t.health.diastolicBloodPressure,
        'glucoseMgDl': t.health.glucoseMgDl,
        'isSmartwatchConnected': t.health.isSmartwatchConnected,
        'smartwatchName': t.health.smartwatchName,
      },
      'confidence': {
        'locationConfidence': t.confidence.locationConfidence,
        'networkConfidence': t.confidence.networkConfidence,
        'motionConfidence': t.confidence.motionConfidence,
        'batteryConfidence': t.confidence.batteryConfidence,
        'healthConfidence': t.confidence.healthConfidence,
        'overallConfidence': t.confidence.overallConfidence,
      },
      'severity': {
        'level': t.severity.level.name,
        'score': t.severity.score,
        'contributingFactors': t.severity.contributingFactors,
      },
    };
  }

  TelemetrySnapshot _telemetryFromJson(Map<String, dynamic> j) {
    final loc = j['location'] as Map<String, dynamic>;
    final dev = j['device'] as Map<String, dynamic>;
    final conn = j['connectivity'] as Map<String, dynamic>;
    final app = j['application'] as Map<String, dynamic>;
    final mot = j['motion'] as Map<String, dynamic>;
    final hlth = j['health'] as Map<String, dynamic>;
    final conf = j['confidence'] as Map<String, dynamic>;
    final sev = j['severity'] as Map<String, dynamic>;

    return TelemetrySnapshot(
      utcTime: DateTime.parse(j['utcTime'] as String),
      localTime: DateTime.parse(j['localTime'] as String),
      monotonicElapsedMs: j['monotonicElapsedMs'] as int,
      location: LocationTelemetry(
        latitude: loc['latitude'] as double?,
        longitude: loc['longitude'] as double?,
        altitude: loc['altitude'] as double?,
        accuracy: loc['accuracy'] as String,
        speed: loc['speed'] as double?,
        heading: loc['heading'] as double?,
        address: loc['address'] as String,
        timestamp: DateTime.parse(loc['timestamp'] as String),
        isGpsEnabled: loc['isGpsEnabled'] as bool,
        isMockLocation: loc['isMockLocation'] as bool? ?? false,
        isoCountryCode: loc['isoCountryCode'] as String?,
      ),
      device: DeviceTelemetry(
        batteryPercent: dev['batteryPercent'] as int,
        isCharging: dev['isCharging'] as bool,
        batteryTemperatureCelsius: dev['batteryTemperatureCelsius'] as double?,
        isBatterySaverEnabled: dev['isBatterySaverEnabled'] as bool,
        isScreenLocked: dev['isScreenLocked'] as bool,
        deviceOrientation: dev['deviceOrientation'] as String? ?? 'portrait',
        deviceName: dev['deviceName'] as String,
        osVersion: dev['osVersion'] as String,
        platform: dev['platform'] as String,
        timeZone: dev['timeZone'] as String,
        locale: dev['locale'] as String,
      ),
      connectivity: ConnectivityTelemetry(
        isInternetAvailable: conn['isInternetAvailable'] as bool,
        connectionType: conn['connectionType'] as String,
        isWifiEnabled: conn['isWifiEnabled'] as bool,
        isMobileDataEnabled: conn['isMobileDataEnabled'] as bool,
        isBluetoothEnabled: conn['isBluetoothEnabled'] as bool,
        isAirplaneModeEnabled: conn['isAirplaneModeEnabled'] as bool,
        signalStrengthDbm: conn['signalStrengthDbm'] as int?,
      ),
      application: ApplicationTelemetry(
        isForeground: app['isForeground'] as bool,
        lastUserInteraction: DateTime.parse(app['lastUserInteraction'] as String),
        sessionDuration: Duration(milliseconds: app['sessionDurationMs'] as int),
        appVersion: app['appVersion'] as String,
      ),
      motion: MotionTelemetry(
        motionState: mot['motionState'] as String,
        confidenceScore: mot['confidenceScore'] as int? ?? 100,
        stepCount: mot['stepCount'] as int?,
      ),
      health: HealthTelemetry(
        heartRateBpm: hlth['heartRateBpm'] as int?,
        bloodOxygenPercent: hlth['bloodOxygenPercent'] as int?,
        systolicBloodPressure: hlth['systolicBloodPressure'] as int?,
        diastolicBloodPressure: hlth['diastolicBloodPressure'] as int?,
        glucoseMgDl: hlth['glucoseMgDl'] as double?,
        isSmartwatchConnected: hlth['isSmartwatchConnected'] as bool? ?? false,
        smartwatchName: hlth['smartwatchName'] as String?,
      ),
      confidence: TelemetryConfidence(
        locationConfidence: conf['locationConfidence'] as int,
        networkConfidence: conf['networkConfidence'] as int,
        motionConfidence: conf['motionConfidence'] as int,
        batteryConfidence: conf['batteryConfidence'] as int,
        healthConfidence: conf['healthConfidence'] as int,
        overallConfidence: conf['overallConfidence'] as int,
      ),
      severity: EmergencySeverity(
        level: EmergencySeverityLevel.values.firstWhere(
          (e) => e.name == sev['level'],
          orElse: () => EmergencySeverityLevel.medium,
        ),
        score: sev['score'] as int,
        contributingFactors: List<String>.from(sev['contributingFactors'] ?? []),
      ),
      sensorHealthMap: const {},
    );
  }

  Map<String, dynamic> _timelineToJson(TimelineEntry e) {
    return {
      'id': e.id,
      'utcTime': e.utcTime.toIso8601String(),
      'localTime': e.localTime.toIso8601String(),
      'monotonicElapsedMs': e.monotonicElapsedMs,
      'title': e.title,
      'description': e.description,
      'eventType': e.eventType,
      'category': e.category,
    };
  }

  TimelineEntry _timelineFromJson(Map<String, dynamic> j) {
    return TimelineEntry(
      id: j['id'] as String,
      utcTime: DateTime.parse(j['utcTime'] as String),
      localTime: DateTime.parse(j['localTime'] as String),
      monotonicElapsedMs: j['monotonicElapsedMs'] as int,
      title: j['title'] as String,
      description: j['description'] as String,
      eventType: j['eventType'] as String,
      category: j['category'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> _sessionMetadataToJson(SessionMetadata s) {
    return {
      'sessionId': s.sessionId,
      'startedAt': s.startedAt.toIso8601String(),
      'isSessionActive': s.isSessionActive,
      'triggerType': s.triggerType,
      'lastPacketNumber': s.lastPacketNumber,
      'lastUpdatedUtc': s.lastUpdatedUtc.toIso8601String(),
    };
  }

  SessionMetadata _sessionMetadataFromJson(Map<String, dynamic> j) {
    return SessionMetadata(
      sessionId: j['sessionId'] as String,
      startedAt: DateTime.parse(j['startedAt'] as String),
      isSessionActive: j['isSessionActive'] as bool,
      triggerType: j['triggerType'] as String,
      lastPacketNumber: j['lastPacketNumber'] as int,
      lastUpdatedUtc: DateTime.parse(j['lastUpdatedUtc'] as String),
    );
  }
}
