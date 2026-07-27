/// telemetry_point.dart
///
/// Immutable domain model representing a single GPS/sensor telemetry sample with quality confidence scoring.

library;

import 'package:flutter/foundation.dart';

enum TelemetryQuality {
  excellent, // accuracy <= 10m
  good,      // accuracy <= 25m
  poor,      // accuracy <= 100m
  rejected,  // accuracy > 100m or invalid
}

@immutable
class TelemetryPoint {
  const TelemetryPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.heading,
    required this.speed,
    required this.timestamp,
    this.quality = TelemetryQuality.good,
    this.confidenceScore = 0.85,
    this.sourceId = 'gps',
  });

  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double heading;
  final double speed;
  final DateTime timestamp;
  final TelemetryQuality quality;
  final double confidenceScore;
  final String sourceId;

  TelemetryPoint copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    double? heading,
    double? speed,
    DateTime? timestamp,
    TelemetryQuality? quality,
    double? confidenceScore,
    String? sourceId,
  }) {
    return TelemetryPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      quality: quality ?? this.quality,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'heading': heading,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
      'quality': quality.name,
      'confidenceScore': confidenceScore,
      'sourceId': sourceId,
    };
  }

  factory TelemetryPoint.fromJson(Map<String, dynamic> json) {
    return TelemetryPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      heading: (json['heading'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      quality: TelemetryQuality.values.firstWhere(
        (q) => q.name == json['quality'],
        orElse: () => TelemetryQuality.good,
      ),
      confidenceScore: ((json['confidenceScore'] ?? 0.85) as num).toDouble(),
      sourceId: (json['sourceId'] as String?) ?? 'gps',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TelemetryPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timestamp == other.timestamp;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode ^ timestamp.hashCode;
}
