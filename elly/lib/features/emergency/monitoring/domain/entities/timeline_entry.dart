/// timeline_entry.dart
///
/// Append-only timeline log entry.

library;

import 'package:equatable/equatable.dart';

class TimelineEntry extends Equatable {
  const TimelineEntry({
    required this.id,
    required this.utcTime,
    required this.localTime,
    required this.monotonicElapsedMs,
    required this.title,
    required this.description,
    required this.eventType,
    this.category = 'system',
  });

  final String id;
  final DateTime utcTime;
  final DateTime localTime;
  final int monotonicElapsedMs;
  final String title;
  final String description;
  final String eventType;
  final String category;

  @override
  List<Object?> get props => [
        id,
        utcTime,
        localTime,
        monotonicElapsedMs,
        title,
        description,
        eventType,
        category,
      ];
}
