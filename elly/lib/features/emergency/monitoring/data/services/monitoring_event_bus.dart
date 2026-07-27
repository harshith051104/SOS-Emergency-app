/// monitoring_event_bus.dart
///
/// In-memory pub-sub Event Bus broadcasting monitoring events to external feature modules.

library;

import 'dart:async';
import '../../domain/entities/monitoring_event.dart';

class MonitoringEventBus {
  MonitoringEventBus()
      : _controller = StreamController<MonitoringEvent>.broadcast();

  final StreamController<MonitoringEvent> _controller;

  /// Stream of all published monitoring events.
  Stream<MonitoringEvent> get eventStream => _controller.stream;

  /// Stream of filtered events of a specific event type [T].
  Stream<T> on<T extends MonitoringEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  /// Publishes a new monitoring event to all subscribers.
  void publish(MonitoringEvent event) {
    if (!_controller.isClosed) {
      Future<void>(() {
        if (!_controller.isClosed) _controller.add(event);
      });
    }
  }

  /// Closes the event bus stream.
  Future<void> dispose() async {
    await _controller.close();
  }
}
