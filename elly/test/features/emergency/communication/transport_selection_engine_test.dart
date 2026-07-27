/// transport_selection_engine_test.dart
///
/// Unit tests for TransportSelectionEngine dynamic scoring.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/communication/data/services/transport_selection_engine.dart';

void main() {
  group('TransportSelectionEngine', () {
    final engine = TransportSelectionEngine();

    test('should select Internet as best transport when online', () {
      final best = engine.selectBestTransport(
        
      );

      expect(best.transportType, equals('internet'));
      expect(best.score, equals(95));
    });

    test('should fallback to SMS when Internet is offline', () {
      final best = engine.selectBestTransport(
        isInternetOnline: false,
      );

      expect(best.transportType, equals('sms'));
      expect(best.score, equals(82));
    });
  });
}
