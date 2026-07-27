/// communication_event_bus.dart
///
/// In-memory pub-sub Event Bus for broadcasting Communication Subsystem events.

library;

import 'dart:async';
import '../../domain/entities/communication_event.dart';

class CommunicationEventBus {
  CommunicationEventBus()
      : _controller = StreamController<CommunicationEvent>.broadcast();

  final StreamController<CommunicationEvent> _controller;

  Stream<CommunicationEvent> get eventStream => _controller.stream;

  Stream<T> on<T extends CommunicationEvent>() {
    return _controller.stream.where((e) => e is T).cast<T>();
  }

  void publish(CommunicationEvent event) {
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
