/// reliability_score.dart
///
/// Domain entity scoring current system-wide reliability (0-100%).

library;

import 'package:equatable/equatable.dart';

class ReliabilityScore extends Equatable {
  const ReliabilityScore({
    required this.connectivityPercent,
    required this.queueHealthPercent,
    required this.recoveryReadinessPercent,
    required this.storageHealthPercent,
    required this.overallScore,
  });

  final int connectivityPercent;
  final int queueHealthPercent;
  final int recoveryReadinessPercent;
  final int storageHealthPercent;
  final int overallScore;

  factory ReliabilityScore.perfect() {
    return const ReliabilityScore(
      connectivityPercent: 100,
      queueHealthPercent: 100,
      recoveryReadinessPercent: 100,
      storageHealthPercent: 100,
      overallScore: 100,
    );
  }

  @override
  List<Object?> get props => [
        connectivityPercent,
        queueHealthPercent,
        recoveryReadinessPercent,
        storageHealthPercent,
        overallScore,
      ];
}
