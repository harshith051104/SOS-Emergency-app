/// cancellation_window_test.dart
///
/// Widget tests for 3-second false alarm cancellation window sheet.

library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/sos/presentation/widgets/details/cancellation_countdown_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cancellation Countdown Sheet Tests', () {
    testWidgets('should render countdown title and cancel button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CancellationCountdownSheet(
              onConfirmProceed: () {},
              onCancelSos: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('ACTIVATING EMERGENCY IN'), findsOneWidget);
      expect(find.text('CANCEL SOS 🛑'), findsOneWidget);
    });
  });
}
