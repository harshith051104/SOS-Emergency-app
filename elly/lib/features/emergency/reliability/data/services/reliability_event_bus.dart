/// reliability_event_bus.dart
///
/// In-memory pub-sub Event Bus for broadcasting Reliability Engine events.

library;

import 'dart:async';
import '../../domain/entities/reliability_event.dart';

class ReliabilityEventBus {
  ReliabilityEventBus()
      : _controller = StreamController<ReliabilityEvent>.broadcast();

  final StreamController<ReliabilityEvent> _controller;

  Stream<ReliabilityEvent> get eventStream => _controller.stream;

  Stream<T> on<T extends ReliabilityEvent>() {
    return _controller.stream.where((e) => e is T).cast<T>();
  }

  void publish(ReliabilityEvent event) {
    if (!_controller.isClosed) {
      Future<void>(() {
        if (!_controller.isClosed) _controller.add(event);
      });
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
