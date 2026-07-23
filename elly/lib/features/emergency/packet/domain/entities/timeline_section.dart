/// timeline_section.dart
///
/// Part of the versioned Emergency Data Packet.
/// Contains logs and events representing milestones in the emergency session.

library;

import 'package:equatable/equatable.dart';

class TimelineEvent extends Equatable {
  const TimelineEvent({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.description,
  });

  final String id;
  final String title;
  final DateTime timestamp;
  final String description;

  TimelineEvent copyWith({
    String? id,
    String? title,
    DateTime? timestamp,
    String? description,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [id, title, timestamp, description];
}

class TimelineSection extends Equatable {
  const TimelineSection({
    required this.events,
  });

  final List<TimelineEvent> events;

  TimelineSection copyWith({
    List<TimelineEvent>? events,
  }) {
    return TimelineSection(
      events: events ?? this.events,
    );
  }

  @override
  List<Object?> get props => [events];
}
