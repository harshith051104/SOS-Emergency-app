/// emergency_activated_page_test.dart
///
/// Widget tests for [EmergencyActivatedPage].

library;

import 'package:elly/features/emergency/sos/domain/entities/emergency_event.dart';
import 'package:elly/features/emergency/sos/domain/enums/emergency_status.dart';
import 'package:elly/features/emergency/sos/domain/enums/emergency_type.dart';
import 'package:elly/features/emergency/sos/presentation/pages/emergency_activated_page.dart';
import 'package:elly/features/emergency/sos/presentation/providers/emergency_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';




import '../../../../../helpers/test_helpers.dart';

void main() {
  group('EmergencyActivatedPage —', () {
    final mockEvent = EmergencyEvent(
      id: 'abcd-1234-efgh-5678',
      type: EmergencyType.manual,
      status: EmergencyStatus.active,
      createdAt: DateTime(2024),
      activatedAt: DateTime(2024),
    );

    testWidgets('renders title and description', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeEmergencyEventProvider.overrideWithValue(mockEvent),
          ],
          child: buildTestApp(const EmergencyActivatedPage()),
        ),
      );
      await tester.pump();

      expect(find.text('SOS Activated'), findsOneWidget);
      expect(find.text('Emergency workflow started.'), findsOneWidget);
    });

    testWidgets('shows truncated event ID', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeEmergencyEventProvider.overrideWithValue(mockEvent),
          ],
          child: buildTestApp(const EmergencyActivatedPage()),
        ),
      );
      await tester.pump();

      // ID starts with 'abcd-123' → shows 'ID: abcd-123…'
      expect(find.textContaining('ID: abcd-123'), findsOneWidget);
    });

    testWidgets('shows Return Home button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeEmergencyEventProvider.overrideWithValue(mockEvent),
          ],
          child: buildTestApp(const EmergencyActivatedPage()),
        ),
      );
      await tester.pump();

      expect(find.text('Return Home'), findsOneWidget);
    });
  });
}
