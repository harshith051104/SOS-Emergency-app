/// transport_health_monitor.dart
///
/// Service continuously tracking health status for every transport channel.

library;

import '../../domain/entities/transport_health.dart';

class TransportHealthMonitor {
  TransportHealthMonitor() {
    _healthMatrix['internet'] = TransportHealth(
      transportType: 'internet',
      status: TransportHealthStatus.healthy,
      consecutiveFailures: 0,
      lastCheck: DateTime.now(),
    );
    _healthMatrix['sms'] = TransportHealth(
      transportType: 'sms',
      status: TransportHealthStatus.healthy,
      consecutiveFailures: 0,
      lastCheck: DateTime.now(),
    );
    _healthMatrix['phone'] = TransportHealth(
      transportType: 'phone',
      status: TransportHealthStatus.healthy,
      consecutiveFailures: 0,
      lastCheck: DateTime.now(),
    );
    _healthMatrix['email'] = TransportHealth(
      transportType: 'email',
      status: TransportHealthStatus.healthy,
      consecutiveFailures: 0,
      lastCheck: DateTime.now(),
    );
    _healthMatrix['bluetooth'] = TransportHealth(
      transportType: 'bluetooth',
      status: TransportHealthStatus.unavailable,
      consecutiveFailures: 0,
      lastCheck: DateTime.now(),
    );
    _healthMatrix['mesh'] = TransportHealth(
      transportType: 'mesh',
      status: TransportHealthStatus.unavailable,
      consecutiveFailures: 0,
      lastCheck: DateTime.now(),
    );
  }

  final Map<String, TransportHealth> _healthMatrix = {};

  Map<String, TransportHealth> get currentMatrix => Map.unmodifiable(_healthMatrix);

  void recordSuccess(String transportType) {
    _healthMatrix[transportType] = TransportHealth(
      transportType: transportType,
      status: TransportHealthStatus.healthy,
      consecutiveFailures: 0,
      lastCheck: DateTime.now(),
    );
  }

  void recordFailure(String transportType) {
    final prev = _healthMatrix[transportType];
    final failures = (prev?.consecutiveFailures ?? 0) + 1;
    final status = failures >= 3 ? TransportHealthStatus.unavailable : TransportHealthStatus.degraded;

    _healthMatrix[transportType] = TransportHealth(
      transportType: transportType,
      status: status,
      consecutiveFailures: failures,
      lastCheck: DateTime.now(),
    );
  }
}
