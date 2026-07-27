/// emergency_event_bus.dart
///
/// Decoupled platform event bus broadcasting engine events across all features
/// (Telemetry, AI Detection, Voice Trigger, Offline Mode, Cloud Sync).

library;

import 'dart:async';

class PlatformEvent {
  const PlatformEvent({
    required this.eventId,
    required this.eventName,
    required this.payload,
    required this.timestamp,
  });

  final String eventId;
  final String eventName;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
}

class EmergencyEventBus {
  EmergencyEventBus() : _controller = StreamController<PlatformEvent>.broadcast();

  final StreamController<PlatformEvent> _controller;

  Stream<PlatformEvent> get events => _controller.stream;

  void publish(String eventName, Map<String, dynamic> payload) {
    if (_controller.isClosed) return;
    _controller.add(PlatformEvent(
      eventId: 'evt_bus_${DateTime.now().millisecondsSinceEpoch}',
      eventName: eventName,
      payload: Map.unmodifiable(payload),
      timestamp: DateTime.now(),
    ));
  }

  void dispose() {
    _controller.close();
  }
}
