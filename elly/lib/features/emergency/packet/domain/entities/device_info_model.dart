/// device_info_model.dart
///
/// Domain model capturing responder device information (battery, network, GPS status).

library;

import 'package:flutter/foundation.dart';

@immutable
class DeviceInfoModel {
  const DeviceInfoModel({
    required this.batteryLevel,
    required this.networkState,
    required this.gpsAvailable,
  });

  final int batteryLevel;
  final String networkState;
  final bool gpsAvailable;

  DeviceInfoModel copyWith({
    int? batteryLevel,
    String? networkState,
    bool? gpsAvailable,
  }) {
    return DeviceInfoModel(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      networkState: networkState ?? this.networkState,
      gpsAvailable: gpsAvailable ?? this.gpsAvailable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batteryLevel': batteryLevel,
      'networkState': networkState,
      'gpsAvailable': gpsAvailable,
    };
  }

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      batteryLevel: json['batteryLevel'] as int? ?? 100,
      networkState: json['networkState'] as String? ?? 'online',
      gpsAvailable: json['gpsAvailable'] as bool? ?? true,
    );
  }
}
