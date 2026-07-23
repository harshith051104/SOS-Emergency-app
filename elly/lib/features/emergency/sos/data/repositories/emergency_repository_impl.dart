/// emergency_repository_impl.dart
///
/// Concrete implementation of [EmergencyRepository].
///
/// Phase 1: Simulates a backend call with [Future.delayed].
/// Phase 2+: Replace the delay with a real HTTP/gRPC client call.
/// The domain and presentation layers are completely unaffected by this swap.

library;

import 'package:uuid/uuid.dart';

import '../../domain/entities/emergency_event.dart';
import '../../domain/enums/emergency_status.dart';
import '../../domain/enums/emergency_type.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../datasources/emergency_local_datasource.dart';

/// Mock repository that simulates async emergency operations locally.
class EmergencyRepositoryImpl implements EmergencyRepository {
  EmergencyRepositoryImpl({
    required EmergencyLocalDataSource localDataSource,
    Uuid uuid = const Uuid(),
  })  : _localDataSource = localDataSource,
        _uuid = uuid;

  final EmergencyLocalDataSource _localDataSource;
  final Uuid _uuid;

  /// Simulated network delay for mock activation.
  static const Duration _mockDelay = Duration(milliseconds: 800);

  @override
  Future<EmergencyEvent> createEmergency(EmergencyType type) async {
    // Simulate async backend call.
    await Future<void>.delayed(_mockDelay);

    final now = DateTime.now();
    final event = EmergencyEvent(
      id: _uuid.v4(),
      type: type,
      status: EmergencyStatus.active,
      createdAt: now,
      activatedAt: now,
    );

    // Persist locally so state survives hot restart during development.
    await _localDataSource.saveEvent(event);

    return event;
  }

  @override
  Future<EmergencyEvent> cancelEmergency(String eventId) async {
    await Future<void>.delayed(_mockDelay);

    final existing = await _localDataSource.getLatestEvent();
    final now = DateTime.now();

    final cancelled = (existing ?? EmergencyEvent(
      id: eventId,
      type: EmergencyType.manual,
      status: EmergencyStatus.cancelled,
      createdAt: now,
    )).copyWith(
      status: EmergencyStatus.cancelled,
      cancelledAt: now,
    );

    await _localDataSource.saveEvent(cancelled);
    return cancelled;
  }

  @override
  Future<EmergencyEvent?> getLatestEmergency() {
    return _localDataSource.getLatestEvent();
  }
}
