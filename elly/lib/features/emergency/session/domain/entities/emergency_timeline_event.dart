/// emergency_timeline_event.dart
///
/// Immutable domain model representing a single recorded event in the emergency timeline.

library;

import 'package:flutter/foundation.dart';

enum EventCategory {
  lifecycle,
  engine,
  location,
  contacts,
  dispatch,
  system,
}

enum EventSeverity {
  info,
  warning,
  error,
  success,
}

@immutable
class EmergencyTimelineEvent {
  const EmergencyTimelineEvent({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.severity,
    required this.title,
    required this.description,
    required this.sourceEngine,
  });

  final String id;
  final DateTime timestamp;
  final EventCategory category;
  final EventSeverity severity;
  final String title;
  final String description;
  final String sourceEngine;

  EmergencyTimelineEvent copyWith({
    String? id,
    DateTime? timestamp,
    EventCategory? category,
    EventSeverity? severity,
    String? title,
    String? description,
    String? sourceEngine,
  }) {
    return EmergencyTimelineEvent(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      sourceEngine: sourceEngine ?? this.sourceEngine,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'category': category.name,
      'severity': severity.name,
      'title': title,
      'description': description,
      'sourceEngine': sourceEngine,
    };
  }

  factory EmergencyTimelineEvent.fromJson(Map<String, dynamic> json) {
    return EmergencyTimelineEvent(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      category: EventCategory.values.firstWhere((e) => e.name == json['category']),
      severity: EventSeverity.values.firstWhere((e) => e.name == json['severity']),
      title: json['title'] as String,
      description: json['description'] as String,
      sourceEngine: json['sourceEngine'] as String,
    );
  }
}
