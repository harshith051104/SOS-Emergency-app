/// location_section.dart
///
/// Part of the versioned Emergency Data Packet.
/// Contains GPS location, geocoding details, accuracy, and mock state.

library;

import 'package:equatable/equatable.dart';

class LocationSection extends Equatable {
  const LocationSection({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.accuracy,
    required this.timestamp,
    required this.permissionStatus,
    required this.isGpsEnabled,
    required this.isMockLocation,
    this.isoCountryCode,
  });

  /// Latitude of the device. Nullable if permissions/GPS are disabled.
  final double? latitude;

  /// Longitude of the device. Nullable if permissions/GPS are disabled.
  final double? longitude;

  /// Reverse-geocoded physical address (e.g. "Hyderabad, India").
  final String address;

  /// Accuracy radius in meters/descriptor (e.g. "5.2m").
  final String accuracy;

  /// Time when this location telemetry was retrieved.
  final DateTime timestamp;

  /// Permission status string from Geolocator (e.g. "whileInUse", "denied").
  final String permissionStatus;

  /// Whether the hardware GPS module is turned on.
  final bool isGpsEnabled;

  /// Flag indicating if the GPS coordinate is simulated/mocked.
  final bool isMockLocation;

  /// ISO country code of the location (e.g. "IN", "US", "GB").
  final String? isoCountryCode;

  LocationSection copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? accuracy,
    DateTime? timestamp,
    String? permissionStatus,
    bool? isGpsEnabled,
    bool? isMockLocation,
    String? isoCountryCode,
  }) {
    return LocationSection(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isGpsEnabled: isGpsEnabled ?? this.isGpsEnabled,
      isMockLocation: isMockLocation ?? this.isMockLocation,
      isoCountryCode: isoCountryCode ?? this.isoCountryCode,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        address,
        accuracy,
        timestamp,
        permissionStatus,
        isGpsEnabled,
        isMockLocation,
        isoCountryCode,
      ];
}
