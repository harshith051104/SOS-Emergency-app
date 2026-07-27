/// transport_config.dart
///
/// Domain entity configuring transport options per queue payload.

library;

import 'package:equatable/equatable.dart';

class TransportConfig extends Equatable {
  const TransportConfig({
    required this.supportedTransports,
    required this.preferredTransport,
    required this.fallbackOrder,
  });

  /// Transports supported (e.g. ['http', 'sms', 'email', 'bluetooth', 'mesh'])
  final List<String> supportedTransports;
  final String preferredTransport;
  final List<String> fallbackOrder;

  factory TransportConfig.defaultHttpWithSmsFallback() {
    return const TransportConfig(
      supportedTransports: ['http', 'sms'],
      preferredTransport: 'http',
      fallbackOrder: ['http', 'sms'],
    );
  }

  @override
  List<Object?> get props => [
        supportedTransports,
        preferredTransport,
        fallbackOrder,
      ];
}
