/// i_transport_repository.dart
///
/// Interface for scoring, selecting, and evaluating health of transport channels.

library;

import '../entities/transport_score.dart';
import '../entities/transport_health.dart';

abstract class ITransportRepository {
  Future<List<TransportScore>> evaluateAllTransports();
  Future<TransportScore> getBestTransport();
  Future<Map<String, TransportHealth>> getTransportHealthMatrix();
}
