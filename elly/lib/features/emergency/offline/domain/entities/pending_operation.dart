/// pending_operation.dart
///
/// Immutable domain model representing a single queued offline operation waiting for synchronization.

library;

import 'package:flutter/foundation.dart';

@immutable
class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.operationType,
    required this.payload,
    required this.timestamp,
    this.retryAttempts = 0,
    this.priority = 1,
    this.completed = false,
  });

  final String id;
  final String operationType;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int retryAttempts;
  final int priority;
  final bool completed;

  PendingOperation copyWith({
    String? id,
    String? operationType,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    int? retryAttempts,
    int? priority,
    bool? completed,
  }) {
    return PendingOperation(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operationType': operationType,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'retryAttempts': retryAttempts,
      'priority': priority,
      'completed': completed,
    };
  }

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'] as String,
      operationType: json['operationType'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryAttempts: json['retryAttempts'] as int? ?? 0,
      priority: json['priority'] as int? ?? 1,
      completed: json['completed'] as bool? ?? false,
    );
  }
}
