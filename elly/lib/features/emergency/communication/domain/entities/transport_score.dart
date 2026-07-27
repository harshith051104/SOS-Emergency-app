/// transport_score.dart
///
/// Score evaluation entity for transport channel selection.

library;

import 'package:equatable/equatable.dart';

class TransportScore extends Equatable {
  const TransportScore({
    required this.transportType,
    required this.score,
    required this.isAvailable,
    required this.ratingFactors,
  });

  final String transportType; // 'internet', 'sms', 'phone', 'email', 'bluetooth', 'mesh'
  final int score; // 0 - 100
  final bool isAvailable;
  final List<String> ratingFactors;

  @override
  List<Object?> get props => [
        transportType,
        score,
        isAvailable,
        ratingFactors,
      ];
}
