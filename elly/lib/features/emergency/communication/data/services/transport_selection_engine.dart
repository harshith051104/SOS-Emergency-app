/// transport_selection_engine.dart
///
/// Dynamic Transport Scoring Engine selecting the optimal communication channel.

library;

import '../../domain/entities/transport_score.dart';
import '../../domain/entities/transport_health.dart';
import 'transport_health_monitor.dart';

class TransportSelectionEngine {
  TransportSelectionEngine({
    TransportHealthMonitor? healthMonitor,
  }) : _healthMonitor = healthMonitor ?? TransportHealthMonitor();

  final TransportHealthMonitor _healthMonitor;

  List<TransportScore> evaluateScores({
    bool isInternetOnline = true,
    bool isCellularAvailable = true,
    bool isBluetoothMeshAvailable = false,
  }) {
    final matrix = _healthMonitor.currentMatrix;
    final scores = <TransportScore>[];

    // 1. Internet Transport (Base 95)
    final internetHealth = matrix['internet']?.status ?? TransportHealthStatus.healthy;
    final internetAvailable = isInternetOnline && internetHealth != TransportHealthStatus.unavailable;
    scores.add(TransportScore(
      transportType: 'internet',
      score: internetAvailable ? (internetHealth == TransportHealthStatus.degraded ? 75 : 95) : 0,
      isAvailable: internetAvailable,
      ratingFactors: [
        if (isInternetOnline) 'Internet reachable' else 'No internet link',
        'Health: ${internetHealth.name}',
      ],
    ));

    // 2. SMS Transport (Base 82)
    final smsHealth = matrix['sms']?.status ?? TransportHealthStatus.healthy;
    final smsAvailable = isCellularAvailable && smsHealth != TransportHealthStatus.unavailable;
    scores.add(TransportScore(
      transportType: 'sms',
      score: smsAvailable ? (smsHealth == TransportHealthStatus.degraded ? 60 : 82) : 0,
      isAvailable: smsAvailable,
      ratingFactors: [
        if (isCellularAvailable) 'Cellular available' else 'No cellular SIM',
        'Health: ${smsHealth.name}',
      ],
    ));

    // 3. Phone Call Transport (Base 70)
    final phoneHealth = matrix['phone']?.status ?? TransportHealthStatus.healthy;
    final phoneAvailable = isCellularAvailable && phoneHealth != TransportHealthStatus.unavailable;
    scores.add(TransportScore(
      transportType: 'phone',
      score: phoneAvailable ? 70 : 0,
      isAvailable: phoneAvailable,
      ratingFactors: [
        if (isCellularAvailable) 'Cellular available' else 'No cellular SIM',
        'Health: ${phoneHealth.name}',
      ],
    ));

    // 4. Email Transport (Base 65)
    scores.add(TransportScore(
      transportType: 'email',
      score: isInternetOnline ? 65 : 0,
      isAvailable: isInternetOnline,
      ratingFactors: [
        if (isInternetOnline) 'Internet reachable' else 'No internet link',
      ],
    ));

    // 5. Bluetooth Relay Transport (Base 60)
    scores.add(TransportScore(
      transportType: 'bluetooth',
      score: isBluetoothMeshAvailable ? 60 : 0,
      isAvailable: isBluetoothMeshAvailable,
      ratingFactors: [
        if (isBluetoothMeshAvailable) 'P2P Bluetooth peer found' else 'No Bluetooth peer',
      ],
    ));

    // 6. Mesh Transport (Base 55)
    scores.add(TransportScore(
      transportType: 'mesh',
      score: isBluetoothMeshAvailable ? 55 : 0,
      isAvailable: isBluetoothMeshAvailable,
      ratingFactors: [
        if (isBluetoothMeshAvailable) 'Mesh route active' else 'No mesh route',
      ],
    ));

    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores;
  }

  TransportScore selectBestTransport({
    bool isInternetOnline = true,
    bool isCellularAvailable = true,
    bool isBluetoothMeshAvailable = false,
  }) {
    final scores = evaluateScores(
      isInternetOnline: isInternetOnline,
      isCellularAvailable: isCellularAvailable,
      isBluetoothMeshAvailable: isBluetoothMeshAvailable,
    );

    return scores.firstWhere(
      (s) => s.isAvailable,
      orElse: () => const TransportScore(
        transportType: 'none',
        score: 0,
        isAvailable: false,
        ratingFactors: ['All transports offline'],
      ),
    );
  }
}
