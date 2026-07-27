/// retention_manager.dart
///
/// Service governing local disk storage retention policies.

library;

import '../../domain/entities/retention_policy.dart';
import '../../domain/repositories/i_packet_storage_repository.dart';

class RetentionManager {
  const RetentionManager(this._storageRepository);

  final IPacketStorageRepository _storageRepository;

  Future<void> enforcePolicy([RetentionPolicy policy = const RetentionPolicy()]) async {
    await _storageRepository.applyRetentionPolicy(policy);
  }
}
