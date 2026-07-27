/// telemetry_source.dart
///
/// Extensible TelemetrySource interface supporting plug-in data streams
/// (GPS, Accelerometer, Gyroscope, Barometer, BLE Wearables) following the Open/Closed Principle.

library;

import 'telemetry_point.dart';

abstract class TelemetrySource {
  String get sourceId;
  String get sourceName;
  Stream<TelemetryPoint> stream();
}
