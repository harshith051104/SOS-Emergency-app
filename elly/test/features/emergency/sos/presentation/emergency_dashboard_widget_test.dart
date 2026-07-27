/// emergency_dashboard_widget_test.dart
///
/// Widget tests for the Single State-Driven Emergency Control Center Dashboard.

library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/sos/presentation/pages/home_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Single Emergency Dashboard UI Tests', () {
    testWidgets('should render all 10 dashboard cards in Normal Protection Mode', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Protection Header
      expect(find.text('ELLY IS PROTECTING YOU'), findsOneWidget);

      // 2. Hero SOS Button
      expect(find.text('TAP FOR SOS'), findsOneWidget);

      // 3. System Status
      expect(find.text('CURRENT SYSTEM STATUS'), findsOneWidget);

      // 4. SOS Circle
      expect(find.text('SOS CIRCLE'), findsOneWidget);

      // 5. Live Location
      expect(find.text('Live Location Sharing'), findsOneWidget);

      // 6. Health Passport
      expect(find.text('HEALTH PASSPORT'), findsOneWidget);

      // 7. Emergency Readiness
      expect(find.text('EMERGENCY READINESS'), findsOneWidget);

      // 8. Emergency History
      expect(find.text('EMERGENCY HISTORY'), findsOneWidget);

      // 9. Trigger Methods
      expect(find.text('HOW SOS CAN BE TRIGGERED'), findsOneWidget);

      // 10. Sticky Floating Quick Actions
      expect(find.text('ACTIVATE SOS'), findsOneWidget);
    });
  });
}
