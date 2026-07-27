/// emergency_confirmation_page_test.dart
///
/// Widget tests for [EmergencyConfirmationPage].

library;

import 'package:elly/features/emergency/sos/domain/enums/emergency_status.dart';
import 'package:elly/features/emergency/sos/presentation/pages/emergency_confirmation_page.dart';
import 'package:elly/features/emergency/sos/presentation/providers/emergency_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';


import '../../../../../helpers/test_helpers.dart';

void main() {
  group('EmergencyConfirmationPage —', () {
    testWidgets('renders title and 6 category buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emergencyStatusProvider
                .overrideWithValue(EmergencyStatus.awaitingConfirmation),
            countdownValueProvider.overrideWithValue(8),
          ],
          child: buildTestApp(const EmergencyConfirmationPage()),
        ),
      );
      await tester.pump();

      expect(find.text('What’s happening?'), findsOneWidget);
      expect(find.text('Choose the situation that matches your emergency.'), findsOneWidget);

      // Verify the 6 emergency category buttons
      expect(find.text('Medical'), findsOneWidget);
      expect(find.text('Personal Safety'), findsOneWidget);
      expect(find.text('Accident'), findsOneWidget);
      expect(find.text('Fire & Disaster'), findsOneWidget);
      expect(find.text('Mental Health'), findsOneWidget);
      expect(find.text('Child & Elderly'), findsOneWidget);

      // Verify bottom banner and 10s timer badge
      expect(find.text('SOS will be activated automatically'), findsOneWidget);
      expect(find.text('8s'), findsOneWidget);
      expect(find.text("I'm Safe"), findsOneWidget);
    });
  });
}
