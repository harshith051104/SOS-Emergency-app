/// emergency_dispatch_request.dart
///
/// Immutable domain model containing all telemetry and metadata needed
/// to execute an emergency dispatch request.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_service_model.dart';


@immutable
class EmergencyDispatchRequest {
  const EmergencyDispatchRequest({
    required this.sessionId,
    required this.triggerSource,
    required this.selectedService,
    required this.selectedEmergencyNumber,
    required this.selectedAt,
    this.userLocation = 'GPS Active • Lat/Lng Attached',
    this.healthPassportReference = 'hp_ref_01',
    this.sosCircleReference = 'circle_ref_01',
    this.isAutomaticSelection = false,
  });

  final String sessionId;
  final String triggerSource;
  final EmergencyService selectedService;
  final String selectedEmergencyNumber;
  final DateTime selectedAt;
  final String? userLocation;
  final String? healthPassportReference;
  final String? sosCircleReference;
  final bool isAutomaticSelection;

  EmergencyDispatchRequest copyWith({
    String? sessionId,
    String? triggerSource,
    EmergencyService? selectedService,
    String? selectedEmergencyNumber,
    DateTime? selectedAt,
    String? userLocation,
    String? healthPassportReference,
    String? sosCircleReference,
    bool? isAutomaticSelection,
  }) {
    return EmergencyDispatchRequest(
      sessionId: sessionId ?? this.sessionId,
      triggerSource: triggerSource ?? this.triggerSource,
      selectedService: selectedService ?? this.selectedService,
      selectedEmergencyNumber: selectedEmergencyNumber ?? this.selectedEmergencyNumber,
      selectedAt: selectedAt ?? this.selectedAt,
      userLocation: userLocation ?? this.userLocation,
      healthPassportReference: healthPassportReference ?? this.healthPassportReference,
      sosCircleReference: sosCircleReference ?? this.sosCircleReference,
      isAutomaticSelection: isAutomaticSelection ?? this.isAutomaticSelection,
    );
  }
}
