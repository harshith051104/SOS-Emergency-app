/// connectivity_monitor_test.dart
///
/// Unit tests for ConnectivityMonitor and capability evaluation.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/reliability/domain/entities/connectivity_state.dart';
import 'package:elly/features/emergency/reliability/data/monitors/connectivity_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityMonitor', () {
    late ConnectivityMonitor monitor;

    setUp(() {
      monitor = ConnectivityMonitor();
    });

    tearDown(() async {
      await monitor.dispose();
    });

    test('should initialize with default offline state', () {
      final state = monitor.currentState;
      expect(state.overallStatus, equals(OverallConnectivityStatus.offline));
      expect(state.isInternetAvailable, isFalse);
    });

    test('should check connectivity now without throwing', () async {
      final state = await monitor.checkConnectivityNow();
      expect(state, isNotNull);
      expect(state.lastUpdated, isNotNull);
    });
  });
}
