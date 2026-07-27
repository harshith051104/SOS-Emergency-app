/// emergency_countdown_page_test.dart
///
/// Widget tests for [EmergencyCountdownPage].

library;

import 'package:elly/features/emergency/sos/domain/enums/emergency_status.dart';
import 'package:elly/features/emergency/sos/presentation/pages/emergency_countdown_page.dart';
import 'package:elly/features/emergency/sos/presentation/providers/emergency_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';


import '../../../../../helpers/test_helpers.dart';

void main() {
  group('EmergencyCountdownPage —', () {
    testWidgets('renders countdown value', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emergencyStatusProvider
                .overrideWithValue(EmergencyStatus.countdown),
            countdownValueProvider.overrideWithValue(3),
          ],
          child: buildTestApp(const EmergencyCountdownPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('SOS will be activated.'), findsOneWidget);
    });

    testWidgets('shows cancel button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emergencyStatusProvider
                .overrideWithValue(EmergencyStatus.countdown),
            countdownValueProvider.overrideWithValue(5),
          ],
          child: buildTestApp(const EmergencyCountdownPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows activating indicator when status is activating',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emergencyStatusProvider
                .overrideWithValue(EmergencyStatus.activating),
            countdownValueProvider.overrideWithValue(0),
          ],
          child: buildTestApp(const EmergencyCountdownPage()),
        ),
      );
      await tester.pump();

      expect(find.text('Activating…'), findsOneWidget);
    });
  });
}
