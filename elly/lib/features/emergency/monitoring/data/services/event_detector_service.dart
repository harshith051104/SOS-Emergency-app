/// event_detector_service.dart
///
/// Service comparing telemetry snapshots to detect significant state changes and generate reason codes.

library;

import '../../domain/entities/telemetry_snapshot.dart';
import '../../domain/entities/timeline_entry.dart';

class EventDetectorResult {
  const EventDetectorResult({
    required this.reasonCode,
    required this.detectedEvents,
  });

  final String reasonCode;
  final List<TimelineEntry> detectedEvents;
}

class EventDetectorService {
  EventDetectorService();

  EventDetectorResult detectStateChanges({
    required TelemetrySnapshot current,
    TelemetrySnapshot? previous,
    required int monotonicMs,
  }) {
    if (previous == null) {
      return EventDetectorResult(
        reasonCode: 'initial_snapshot',
        detectedEvents: [
          TimelineEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            utcTime: current.utcTime,
            localTime: current.localTime,
            monotonicElapsedMs: monotonicMs,
            title: 'Monitoring Engine Started',
            description: 'Initial telemetry snapshot collected.',
            eventType: 'engine_started',
          ),
        ],
      );
    }

    final events = <TimelineEntry>[];
    String? primaryReasonCode;

    // 1. Battery level changed significantly (>= 5% change or charging state change)
    if (previous.device.isCharging != current.device.isCharging) {
      final title = current.device.isCharging ? 'Charging Started' : 'Charging Stopped';
      primaryReasonCode ??= current.device.isCharging ? 'event_charging_started' : 'event_charging_stopped';
      events.add(_createEvent(
        current: current,
        monotonicMs: monotonicMs,
        title: title,
        description: 'Battery level at ${current.device.batteryPercent}%.',
        eventType: 'battery_charging_changed',
      ));
    } else if ((previous.device.batteryPercent - current.device.batteryPercent).abs() >= 5) {
      primaryReasonCode ??= 'event_battery_changed';
      events.add(_createEvent(
        current: current,
        monotonicMs: monotonicMs,
        title: 'Battery Level Changed',
        description: 'Battery level changed from ${previous.device.batteryPercent}% to ${current.device.batteryPercent}%.',
        eventType: 'battery_level_changed',
      ));
    }

    // 2. Connectivity changed
    if (previous.connectivity.isInternetAvailable != current.connectivity.isInternetAvailable) {
      final isConnected = current.connectivity.isInternetAvailable;
      primaryReasonCode ??= isConnected ? 'event_internet_connected' : 'event_internet_lost';
      events.add(_createEvent(
        current: current,
        monotonicMs: monotonicMs,
        title: isConnected ? 'Internet Connection Recovered' : 'Internet Connection Lost',
        description: 'Connection type: ${current.connectivity.connectionType}.',
        eventType: 'connectivity_changed',
      ));
    }

    // 3. Airplane mode toggled
    if (previous.connectivity.isAirplaneModeEnabled != current.connectivity.isAirplaneModeEnabled) {
      final enabled = current.connectivity.isAirplaneModeEnabled;
      primaryReasonCode ??= enabled ? 'event_airplane_mode_enabled' : 'event_airplane_mode_disabled';
      events.add(_createEvent(
        current: current,
        monotonicMs: monotonicMs,
        title: enabled ? 'Airplane Mode Enabled' : 'Airplane Mode Disabled',
        description: 'Network sensors affected by airplane mode toggle.',
        eventType: 'airplane_mode_changed',
      ));
    }

    // 4. GPS status changed
    if (previous.location.isGpsEnabled != current.location.isGpsEnabled) {
      final enabled = current.location.isGpsEnabled;
      primaryReasonCode ??= enabled ? 'event_gps_recovered' : 'event_gps_lost';
      events.add(_createEvent(
        current: current,
        monotonicMs: monotonicMs,
        title: enabled ? 'GPS Service Recovered' : 'GPS Service Lost/Disabled',
        description: current.location.address,
        eventType: 'gps_status_changed',
      ));
    }

    // 5. Significant location shift
    if (previous.location.hasValidCoordinates && current.location.hasValidCoordinates) {
      final pLat = previous.location.latitude!;
      final pLng = previous.location.longitude!;
      final cLat = current.location.latitude!;
      final cLng = current.location.longitude!;
      if ((pLat - cLat).abs() > 0.001 || (pLng - cLng).abs() > 0.001) {
        primaryReasonCode ??= 'event_location_changed';
        events.add(_createEvent(
          current: current,
          monotonicMs: monotonicMs,
          title: 'Location Shift Detected',
          description: current.location.address,
          eventType: 'location_changed',
        ));
      }
    }

    // 6. Motion state changed
    if (previous.motion.motionState != current.motion.motionState) {
      primaryReasonCode ??= 'event_motion_changed';
      events.add(_createEvent(
        current: current,
        monotonicMs: monotonicMs,
        title: 'Motion State Transition',
        description: 'Motion state changed from ${previous.motion.motionState} to ${current.motion.motionState}.',
        eventType: 'motion_changed',
      ));
    }

    // 7. Severity level changed
    if (previous.severity.level != current.severity.level) {
      primaryReasonCode ??= 'event_severity_changed';
      events.add(_createEvent(
        current: current,
        monotonicMs: monotonicMs,
        title: 'Emergency Severity Shift: ${current.severity.level.name.toUpperCase()}',
        description: 'Risk score: ${current.severity.score}. Factors: ${current.severity.contributingFactors.join(', ')}.',
        eventType: 'severity_changed',
      ));
    }

    return EventDetectorResult(
      reasonCode: primaryReasonCode ?? 'periodic_cycle',
      detectedEvents: events,
    );
  }

  TimelineEntry _createEvent({
    required TelemetrySnapshot current,
    required int monotonicMs,
    required String title,
    required String description,
    required String eventType,
  }) {
    return TimelineEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      utcTime: current.utcTime,
      localTime: current.localTime,
      monotonicElapsedMs: monotonicMs,
      title: title,
      description: description,
      eventType: eventType,
      category: 'telemetry_event',
    );
  }
}
