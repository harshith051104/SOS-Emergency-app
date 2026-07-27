/// emergency_service_repository_impl.dart
///
/// Data layer implementation for resolving national emergency services.

library;

import 'package:flutter/material.dart';
import '../../domain/entities/emergency_service_model.dart';
import '../../domain/repositories/emergency_service_repository.dart';

class EmergencyServiceRepositoryImpl implements EmergencyServiceRepository {
  static const List<EmergencyService> _defaultServices = [
    EmergencyService(
      id: 'srv_medical',
      name: 'Medical Emergency',
      description: 'Ambulance, Trauma & Paramedic Dispatch',
      emergencyNumber: '102 / 108',
      icon: Icons.local_hospital_rounded,
      category: 'medical',
      priority: 1,
    ),
    EmergencyService(
      id: 'srv_police',
      name: 'Police Emergency',
      description: 'Law Enforcement, Safety & Threat Protection',
      emergencyNumber: '100',
      icon: Icons.local_police_rounded,
      category: 'police',
      priority: 2,
    ),
    EmergencyService(
      id: 'srv_fire',
      name: 'Fire Rescue',
      description: 'Firefighting, Gas Leak & Rescue Response',
      emergencyNumber: '101',
      icon: Icons.local_fire_department_rounded,
      category: 'fire',
      priority: 3,
    ),
    EmergencyService(
      id: 'srv_traffic',
      name: 'Traffic Police',
      description: 'Highway Patrol, Collision & Traffic Control',
      emergencyNumber: '103',
      icon: Icons.traffic_rounded,
      category: 'traffic',
      priority: 4,
    ),
    EmergencyService(
      id: 'srv_disaster',
      name: 'Disaster Control',
      description: 'Natural Calamity, Flood & Search Response',
      emergencyNumber: '1096',
      icon: Icons.cyclone_rounded,
      category: 'disaster',
      priority: 5,
    ),
    EmergencyService(
      id: 'srv_universal',
      name: 'Universal Helpline',
      description: 'National Unified Emergency Response Standard',
      emergencyNumber: '112',
      icon: Icons.emergency_rounded,
      category: 'universal',
      priority: 6,
    ),
  ];

  @override
  Future<List<EmergencyService>> getAvailableServices({String countryCode = 'IN'}) async {
    // Returns the 6 primary emergency services
    return _defaultServices;
  }

  @override
  Future<EmergencyService?> getDefaultUniversalService({String countryCode = 'IN'}) async {
    return _defaultServices.firstWhere((s) => s.id == 'srv_universal');
  }
}
