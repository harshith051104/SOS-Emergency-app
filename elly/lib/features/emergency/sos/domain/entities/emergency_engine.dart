/// emergency_engine.dart
///
/// Shared engine interface defining capabilities registry and standardized lifecycle hooks
/// (initialize, dispose) across all emergency platform engines.

library;

import 'package:flutter/foundation.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_context.dart';

@immutable
class EmergencyCapability {
  const EmergencyCapability({
    this.supportsRecovery = true,
    this.supportsOfflineMode = true,
    this.requiresLocation = false,
    this.requiresNetwork = false,
  });

  final bool supportsRecovery;
  final bool supportsOfflineMode;
  final bool requiresLocation;
  final bool requiresNetwork;
}

abstract class EmergencyEngine {
  String get engineId;
  String get engineName;
  EmergencyCapability get capabilities;

  Future<void> initialize(EmergencyContext context);
  Future<void> dispose();
}
