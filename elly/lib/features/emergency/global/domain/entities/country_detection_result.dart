/// country_detection_result.dart
///
/// Priority detection result containing country code, confidence score (0.0–1.0), and detection source.

library;

import 'package:flutter/foundation.dart';

enum DetectionSource {
  gps,
  mobileNetwork,
  sim,
  locale,
  manualOverride,
}

@immutable
class CountryDetectionResult {
  const CountryDetectionResult({
    required this.countryCode,
    required this.confidence,
    required this.source,
    required this.timestamp,
  });

  final String countryCode;
  final double confidence;
  final DetectionSource source;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'confidence': confidence,
        'source': source.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CountryDetectionResult.fromJson(Map<String, dynamic> json) => CountryDetectionResult(
        countryCode: json['countryCode'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        source: DetectionSource.values.firstWhere((e) => e.name == json['source']),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
