/// home_page_test.dart
///
/// Widget tests for [HomePage].
/// Verifies that the SOS button renders and tapping it triggers the emergency flow.

library;

import 'package:elly/features/emergency/responders/domain/usecases/get_responders_usecase.dart';
import 'package:elly/features/emergency/responders/presentation/providers/responder_providers.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_config.dart';
import 'package:elly/features/emergency/sos/domain/enums/emergency_status.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_risk_evaluator.dart';
import 'package:elly/features/emergency/sos/domain/usecases/cancel_emergency_usecase.dart';
import 'package:elly/features/emergency/sos/domain/usecases/create_emergency_usecase.dart';
import 'package:elly/features/emergency/sos/presentation/pages/home_page.dart';
import 'package:elly/features/emergency/sos/presentation/widgets/sos_button.dart';
import 'package:elly/features/emergency/sos/presentation/providers/emergency_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_helpers.dart';

// Mocks
class MockCreateEmergencyUseCase extends Mock implements CreateEmergencyUseCase {}
class MockCancelEmergencyUseCase extends Mock implements CancelEmergencyUseCase {}
class MockGetRespondersUseCase extends Mock implements GetRespondersUseCase {}
class MockEmergencyRiskEvaluator extends Mock implements EmergencyRiskEvaluator {}

void main() {
  late MockCreateEmergencyUseCase mockCreate;
  late MockCancelEmergencyUseCase mockCancel;
  late MockGetRespondersUseCase mockGetResponders;
  late MockEmergencyRiskEvaluator mockRiskEvaluator;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockCreate = MockCreateEmergencyUseCase();
    mockCancel = MockCancelEmergencyUseCase();
    mockGetResponders = MockGetRespondersUseCase();
    mockRiskEvaluator = MockEmergencyRiskEvaluator();

    when(() => mockRiskEvaluator.shouldSkipConfirmation()).thenAnswer((_) async => false);
    when(() => mockGetResponders()).thenAnswer((_) async => []);
  });

  group('HomePage —', () {
    testWidgets('renders SOS button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            createEmergencyUseCaseProvider.overrideWithValue(mockCreate),
            cancelEmergencyUseCaseProvider.overrideWithValue(mockCancel),
            getRespondersUseCaseProvider.overrideWithValue(mockGetResponders),
            emergencyRiskEvaluatorProvider.overrideWithValue(mockRiskEvaluator),
          ],
          child: buildTestApp(const HomePage()),
        ),
      );
      await tester.pump();

      expect(find.text('SOS'), findsOneWidget);
      expect(find.text('Emergency'), findsOneWidget);
    });

    testWidgets('tapping SOS button transitions to awaitingConfirmation state', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const HomePage(),
          overrides: [
            createEmergencyUseCaseProvider.overrideWithValue(mockCreate),
            cancelEmergencyUseCaseProvider.overrideWithValue(mockCancel),
            getRespondersUseCaseProvider.overrideWithValue(mockGetResponders),
            emergencyRiskEvaluatorProvider.overrideWithValue(mockRiskEvaluator),
          ],
        ),
      );
      await tester.pump();

      // Read status from active container before tap
      final container = ProviderScope.containerOf(tester.element(find.byType(HomePage)));
      expect(
        container.read(emergencyControllerProvider).status,
        EmergencyStatus.idle,
      );

      await tester.tap(find.byType(SosButton));
      await tester.pumpAndSettle();

      // Should now be in awaitingConfirmation state
      expect(
        container.read(emergencyControllerProvider).status,
        EmergencyStatus.awaitingConfirmation,
      );
    });
  });
}
