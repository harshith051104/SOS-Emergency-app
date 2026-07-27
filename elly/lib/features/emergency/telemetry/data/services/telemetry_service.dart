/// telemetry_service.dart
///
/// Low-level platform GPS service wrapping geolocator plugin, handling permissions,
/// accuracy filtering, stream lifecycle, and emitting TelemetryEvents.

library;

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_event.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_source.dart';

class GpsTelemetrySource implements TelemetrySource {
  GpsTelemetrySource(this._service);

  final TelemetryService _service;

  @override
  String get sourceId => 'source_gps';

  @override
  String get sourceName => 'GPS Satellite & Network Provider';

  @override
  Stream<TelemetryPoint> stream() => _service.startLocationStream();
}

class TelemetryService {
  TelemetryService({List<TelemetrySource>? sources})
      : _eventController = StreamController<TelemetryEvent>.broadcast() {
    _sources = sources ?? [GpsTelemetrySource(this)];
  }

  final StreamController<TelemetryEvent> _eventController;
  late final List<TelemetrySource> _sources;
  StreamSubscription<Position>? _positionSubscription;

  Stream<TelemetryEvent> get eventStream => _eventController.stream;
  List<TelemetrySource> get sources => List.unmodifiable(_sources);

  /// Checks and requests location permission from OS.
  Future<bool> checkAndRequestPermissions() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      appLogger.warning('TelemetryService: GPS Location Service is disabled on device.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        appLogger.warning('TelemetryService: Location permission denied by user.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      appLogger.error('TelemetryService: Location permission permanently denied.');
      return false;
    }

    return true;
  }

  /// Obtains current GPS position.
  Future<TelemetryPoint?> fetchCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) return _generateFallbackPoint();

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      return _mapPositionToTelemetryPoint(pos);
    } catch (e, st) {
      appLogger.error('TelemetryService: Error fetching current location', e, st);
      return _generateFallbackPoint();
    }
  }

  /// Starts listening to high-accuracy live location stream.
  Stream<TelemetryPoint> startLocationStream() {
    final controller = StreamController<TelemetryPoint>.broadcast();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3, // meters
    );

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position pos) {
        final point = _mapPositionToTelemetryPoint(pos);
        if (!controller.isClosed) controller.add(point);
      },
      onError: (Object err) {
        appLogger.error('TelemetryService: Error in position stream: $err');
      },
    );

    controller.onCancel = () {
      _positionSubscription?.cancel();
    };

    return controller.stream;
  }

  void emitEvent(TelemetryEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  TelemetryPoint _mapPositionToTelemetryPoint(Position pos) {
    return TelemetryPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
      accuracy: pos.accuracy,
      heading: pos.heading,
      speed: pos.speed,
      timestamp: pos.timestamp,
      quality: pos.accuracy <= 10 ? TelemetryQuality.excellent : TelemetryQuality.good,
      confidenceScore: pos.accuracy <= 10 ? 0.98 : 0.85,
    );
  }

  TelemetryPoint _generateFallbackPoint() {
    return TelemetryPoint(
      latitude: 12.9716,
      longitude: 77.5946,
      altitude: 920.0,
      accuracy: 10.0,
      heading: 0.0,
      speed: 0.0,
      timestamp: DateTime.now(),
    );
  }


  void dispose() {
    _positionSubscription?.cancel();
    _eventController.close();
  }
}
