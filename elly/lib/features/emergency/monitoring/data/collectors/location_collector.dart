/// location_collector.dart
///
/// Bounded timeout collector for device GPS location & geocoding.

library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../domain/entities/sensor_health.dart';
import '../../domain/entities/telemetry_snapshot.dart';
import 'base_collector.dart';

class LocationCollector extends BaseTelemetryCollector<LocationTelemetry> {
  const LocationCollector({
    this.geolocatorOverride,
  });

  final Object? geolocatorOverride;

  @override
  SensorType get sensorType => SensorType.location;

  @override
  Duration get defaultTimeoutBudget => const Duration(milliseconds: 2000);

  @override
  Future<LocationTelemetry> collect({Duration? timeoutBudget}) async {
    final budget = timeoutBudget ?? defaultTimeoutBudget;
    final fallbackTime = DateTime.now();

    try {
      return await _fetchLocation().timeout(budget);
    } catch (e) {
      debugPrint('LocationCollector: Timed out or failed: $e');
      return LocationTelemetry(
        accuracy: 'Unavailable',
        address: 'Location Fetch Failed: $e',
        timestamp: fallbackTime,
        isGpsEnabled: false,
      );
    }
  }

  Future<LocationTelemetry> _fetchLocation() async {
    final now = DateTime.now();
    bool isGpsEnabled = false;

    try {
      isGpsEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        return LocationTelemetry(
          accuracy: 'Disabled',
          address: 'GPS Service Disabled',
          timestamp: now,
          isGpsEnabled: false,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return LocationTelemetry(
          accuracy: 'Denied',
          address: 'Permission Denied ($permission)',
          timestamp: now,
          isGpsEnabled: isGpsEnabled,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(milliseconds: 1500));

      String address =
          'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}';
      String? countryCode;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(milliseconds: 800));

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          countryCode = p.isoCountryCode;
          final parts = <String>[
            if (p.street != null && p.street!.isNotEmpty) p.street!,
            if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.country != null && p.country!.isNotEmpty) p.country!,
          ];
          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }
        }
      } catch (_) {}

      return LocationTelemetry(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: '${position.accuracy.toStringAsFixed(1)}m',
        speed: position.speed,
        heading: position.heading,
        address: address,
        timestamp: DateTime.now(),
        isGpsEnabled: isGpsEnabled,
        isMockLocation: position.isMocked,
        isoCountryCode: countryCode,
      );
    } catch (e) {
      return LocationTelemetry(
        accuracy: 'Error',
        address: 'Location Hardware Error: $e',
        timestamp: now,
        isGpsEnabled: isGpsEnabled,
      );
    }
  }
}
