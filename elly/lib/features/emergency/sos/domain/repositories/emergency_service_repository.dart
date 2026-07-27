/// emergency_service_repository.dart
///
/// Domain repository interface for retrieving national emergency services.

library;

import '../entities/emergency_service_model.dart';

abstract interface class EmergencyServiceRepository {
  Future<List<EmergencyService>> getAvailableServices({String countryCode = 'IN'});
  Future<EmergencyService?> getDefaultUniversalService({String countryCode = 'IN'});
}
