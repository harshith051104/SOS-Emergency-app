/// location_service.dart
///
/// Wraps Geolocator and Geocoding libraries. Resolves current coordinates
/// and reverse-geocodes to physical address. Gracefully handles errors and denials.

library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../domain/entities/location_section.dart';

class LocationService {
  const LocationService();

  /// Pulls the latest device position and resolves the physical address.
  /// Falls back gracefully on exceptions or lack of permissions.
  Future<LocationSection> getCurrentLocation() async {
    bool isGpsEnabled = false;
    LocationPermission permission = LocationPermission.denied;
    double? latitude;
    double? longitude;
    String accuracy = 'Unknown';
    String address = 'Address Unavailable';
    bool isMocked = false;

    try {
      // 1. Check if hardware GPS is enabled
      isGpsEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        return LocationSection(
          latitude: null,
          longitude: null,
          address: 'GPS Location Service Disabled',
          accuracy: 'No signal',
          timestamp: DateTime.now(),
          permissionStatus: 'unknown',
          isGpsEnabled: false,
          isMockLocation: false,
        );
      }

      // 2. Check permission state
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request once just in case
        permission = await Geolocator.requestPermission();
      }

      final hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (!hasPermission) {
        return LocationSection(
          latitude: null,
          longitude: null,
          address: 'Location Permission Denied ($permission)',
          accuracy: 'Blocked',
          timestamp: DateTime.now(),
          permissionStatus: permission.name,
          isGpsEnabled: isGpsEnabled,
          isMockLocation: false,
        );
      }

      // 3. Fetch GPS coordinates (with timeout to prevent freezing)
      final position = await Geolocator.getCurrentPosition(
        
      ).timeout(const Duration(seconds: 4));

      latitude = position.latitude;
      longitude = position.longitude;
      accuracy = '${position.accuracy.toStringAsFixed(1)}m';
      isMocked = position.isMocked;

      String? countryCode;

      // 4. Reverse geocode to address
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 3));

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          countryCode = p.isoCountryCode;
          final parts = <String>[
            if (p.street != null && p.street!.isNotEmpty) p.street!,
            if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea!,
            if (p.country != null && p.country!.isNotEmpty) p.country!,
          ];
          address = parts.join(', ');
        }
      } catch (e) {
        // Reverse geocoding failed (e.g. no internet/service unavailable), use coordinates string as fallback
        address = 'Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)}';
        debugPrint('LocationService: Geocoding failed: $e');
      }

      return LocationSection(
        latitude: latitude,
        longitude: longitude,
        address: address,
        accuracy: accuracy,
        timestamp: DateTime.now(),
        permissionStatus: permission.name,
        isGpsEnabled: isGpsEnabled,
        isMockLocation: isMocked,
        isoCountryCode: countryCode,
      );
    } catch (e) {
      debugPrint('LocationService: Failed to retrieve coordinates: $e');
      return LocationSection(
        latitude: null,
        longitude: null,
        address: address == 'Address Unavailable'
            ? 'Failed to resolve location details: $e'
            : address,
        accuracy: 'Unavailable',
        timestamp: DateTime.now(),
        permissionStatus: permission.name,
        isGpsEnabled: isGpsEnabled,
        isMockLocation: isMocked,
      );
    }
  }
}
