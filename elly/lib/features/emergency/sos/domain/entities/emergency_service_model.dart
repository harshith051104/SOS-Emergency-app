/// emergency_service_model.dart
///
/// Domain entity and selection result models for the Emergency Service Selection System.

library;

import 'package:flutter/material.dart';

class EmergencyService {
  const EmergencyService({
    required this.id,
    required this.name,
    required this.description,
    required this.emergencyNumber,
    required this.icon,
    required this.category,
    required this.priority,
    this.supportedCountries = const ['IN', 'US', 'UK', 'EU'],
    this.available = true,
  });

  final String id;
  final String name;
  final String description;
  final String emergencyNumber;
  final IconData icon;
  final String category;
  final int priority;
  final List<String> supportedCountries;
  final bool available;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyService && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class EmergencySelectionResult {
  const EmergencySelectionResult({
    required this.selectedService,
    required this.triggerSource,
    required this.selectedAt,
    this.country = 'IN',
    this.isAutomaticSelection = false,
  });

  final EmergencyService selectedService;
  final String triggerSource;
  final DateTime selectedAt;
  final String country;
  final bool isAutomaticSelection;
}

sealed class EmergencySelectionEvent {
  const EmergencySelectionEvent();
}

class ServiceSelectedEvent extends EmergencySelectionEvent {
  const ServiceSelectedEvent({required this.service});
  final EmergencyService service;
}

class SelectionCompletedEvent extends EmergencySelectionEvent {
  const SelectionCompletedEvent({required this.result});
  final EmergencySelectionResult result;
}
