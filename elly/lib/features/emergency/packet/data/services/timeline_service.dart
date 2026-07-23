/// timeline_service.dart
///
/// Centralized service to manage, register, and clear emergency timeline logs
/// triggered by core platform, wearable sensors, AI modules, or response centers.

library;

import 'package:uuid/uuid.dart';
import '../../domain/entities/timeline_section.dart';

class TimelineService {
  TimelineService() : _uuid = const Uuid();

  final Uuid _uuid;
  final List<TimelineEvent> _events = [];

  /// Returns an immutable read-only view of currently logged timeline events.
  List<TimelineEvent> get events => List.unmodifiable(_events);

  /// Appends a new milestone event log.
  void append({required String title, required String description}) {
    _events.add(TimelineEvent(
      id: _uuid.v4(),
      title: title,
      timestamp: DateTime.now(),
      description: description,
    ));
  }

  /// Removes a single event log by ID.
  void remove(String id) {
    _events.removeWhere((event) => event.id == id);
  }

  /// Reset the timeline.
  void clear() {
    _events.clear();
  }
}
