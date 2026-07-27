/// transport_repository_impl.dart
///
/// Implementation of ITransportRepository.

library;

import '../../domain/entities/transport_score.dart';
import '../../domain/entities/transport_health.dart';
import '../../domain/repositories/i_transport_repository.dart';
import '../services/transport_selection_engine.dart';
import '../services/transport_health_monitor.dart';

class TransportRepositoryImpl implements ITransportRepository {
  TransportRepositoryImpl({
    required TransportSelectionEngine selectionEngine,
    required TransportHealthMonitor healthMonitor,
  })  : _selectionEngine = selectionEngine,
        _healthMonitor = healthMonitor;

  final TransportSelectionEngine _selectionEngine;
  final TransportHealthMonitor _healthMonitor;

  @override
  Future<List<TransportScore>> evaluateAllTransports() async {
    return _selectionEngine.evaluateScores();
  }

  @override
  Future<TransportScore> getBestTransport() async {
    return _selectionEngine.selectBestTransport();
  }

  @override
  Future<Map<String, TransportHealth>> getTransportHealthMatrix() async {
    return _healthMonitor.currentMatrix;
  }
}
