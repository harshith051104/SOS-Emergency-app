/// escalation_policy.dart
///
/// Multi-step escalation policy sequence entity.

library;

import 'package:equatable/equatable.dart';

class EscalationPolicy extends Equatable {
  const EscalationPolicy({
    required this.primaryTransport,
    required this.fallbackSequence,
    required this.maxRetriesPerTransport,
  });

  final String primaryTransport;
  final List<String> fallbackSequence; // ['internet', 'sms', 'phone']
  final int maxRetriesPerTransport;

  factory EscalationPolicy.defaultEmergency() {
    return const EscalationPolicy(
      primaryTransport: 'internet',
      fallbackSequence: ['internet', 'sms', 'phone'],
      maxRetriesPerTransport: 2,
    );
  }

  @override
  List<Object?> get props => [
        primaryTransport,
        fallbackSequence,
        maxRetriesPerTransport,
      ];
}
