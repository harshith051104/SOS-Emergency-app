/// emergency_providers_test.dart
///
/// Unit tests for [EmergencyController] state machine transitions in the
/// new session-based SOS flow.

library;

import 'package:elly/features/emergency/responders/domain/usecases/get_responders_usecase.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_config.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_event.dart';
import 'package:elly/features/emergency/sos/domain/enums/emergency_status.dart';

import 'package:elly/features/emergency/sos/domain/enums/emergency_type.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_risk_evaluator.dart';
import 'package:elly/features/emergency/sos/domain/usecases/cancel_emergency_usecase.dart';
import 'package:elly/features/emergency/sos/domain/usecases/create_emergency_usecase.dart';
import 'package:elly/features/emergency/sos/presentation/controllers/emergency_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:elly/features/emergency/packet/data/services/location_service.dart';
import 'package:elly/features/emergency/packet/domain/entities/location_section.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockCreateEmergencyUseCase extends Mock
    implements CreateEmergencyUseCase {}

class MockCancelEmergencyUseCase extends Mock
    implements CancelEmergencyUseCase {}

class MockGetRespondersUseCase extends Mock
    implements GetRespondersUseCase {}

class MockEmergencyRiskEvaluator extends Mock
    implements EmergencyRiskEvaluator {}

class MockLocationService extends Mock implements LocationService {}

// ── Helpers ───────────────────────────────────────────────────────────────────

EmergencyController _makeController({
  required CreateEmergencyUseCase createUseCase,
  required CancelEmergencyUseCase cancelUseCase,
  required GetRespondersUseCase getRespondersUseCase,
  required EmergencyRiskEvaluator riskEvaluator,
  LocationService? locationService,
  EmergencyConfig config = const EmergencyConfig(confirmationDuration: 2),
}) {
  final locService = locationService ?? MockLocationService();
  if (locationService == null) {
    when(() => locService.getCurrentLocation()).thenAnswer((_) async => LocationSection(
      latitude: 17.3850,
      longitude: 78.4867,
      address: 'Hyderabad, India',
      accuracy: '5m',
      timestamp: DateTime.now(),
      permissionStatus: 'whileInUse',
      isGpsEnabled: true,
      isMockLocation: false,
      isoCountryCode: 'IN',
    ));
  }
  return EmergencyController(
    createEmergencyUseCase: createUseCase,
    cancelEmergencyUseCase: cancelUseCase,
    getRespondersUseCase: getRespondersUseCase,
    config: config,
    riskEvaluator: riskEvaluator,
    locationService: locService,
  );
}

EmergencyEvent _mockEvent() => EmergencyEvent(
      id: 'test-uuid-1234',
      type: EmergencyType.manual,
      status: EmergencyStatus.active,
      createdAt: DateTime(2024),
      activatedAt: DateTime(2024),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockCreateEmergencyUseCase mockCreate;
  late MockCancelEmergencyUseCase mockCancel;
  late MockGetRespondersUseCase mockGetResponders;
  late MockEmergencyRiskEvaluator mockRiskEvaluator;

  setUpAll(() {
    registerFallbackValue(EmergencyType.manual);
    registerFallbackValue('');
  });

  setUp(() {
    mockCreate = MockCreateEmergencyUseCase();
    mockCancel = MockCancelEmergencyUseCase();
    mockGetResponders = MockGetRespondersUseCase();
    mockRiskEvaluator = MockEmergencyRiskEvaluator();

    // Default mock setup
    when(() => mockRiskEvaluator.shouldSkipConfirmation()).thenAnswer((_) async => false);
    when(() => mockGetResponders()).thenAnswer((_) async => []);
    when(() => mockCreate(any())).thenAnswer((_) async => _mockEvent());
    when(() => mockCancel(any())).thenAnswer((_) async => _mockEvent());
  });

  group('EmergencyController —', () {
    test('initial state is idle', () {
      final controller = _makeController(
        createUseCase: mockCreate,
        cancelUseCase: mockCancel,
        getRespondersUseCase: mockGetResponders,
        riskEvaluator: mockRiskEvaluator,
      );

      expect(controller.state.status, EmergencyStatus.idle);
      expect(controller.state.countdownValue, 0);
      expect(controller.state.activeEvent, isNull);
    });

    test('requestConfirmation transitions idle → awaitingConfirmation', () async {
      final controller = _makeController(
        createUseCase: mockCreate,
        cancelUseCase: mockCancel,
        getRespondersUseCase: mockGetResponders,
        riskEvaluator: mockRiskEvaluator,
      );

      await controller.requestConfirmation();

      expect(controller.state.status, EmergencyStatus.awaitingConfirmation);
      expect(controller.state.countdownValue, 2);
    });

    test('requestConfirmation is no-op when locked', () async {
      final controller = _makeController(
        createUseCase: mockCreate,
        cancelUseCase: mockCancel,
        getRespondersUseCase: mockGetResponders,
        riskEvaluator: mockRiskEvaluator,
      );

      await controller.requestConfirmation();
      await controller.requestConfirmation();

      expect(controller.state.status, EmergencyStatus.awaitingConfirmation);
    });

    test('markUserSafe transitions awaitingConfirmation → cancelled → idle', () async {
      final controller = _makeController(
        createUseCase: mockCreate,
        cancelUseCase: mockCancel,
        getRespondersUseCase: mockGetResponders,
        riskEvaluator: mockRiskEvaluator,
      );

      await controller.requestConfirmation();
      final future = controller.markUserSafe();

      expect(controller.state.status, EmergencyStatus.cancelled);
      await future;
      expect(controller.state.status, EmergencyStatus.idle);
    });

    test('activateImmediately transitions awaitingConfirmation → active', () async {
      when(() => mockCreate(any())).thenAnswer((_) async => _mockEvent());

      final controller = _makeController(
        createUseCase: mockCreate,
        cancelUseCase: mockCancel,
        getRespondersUseCase: mockGetResponders,
        riskEvaluator: mockRiskEvaluator,
      );

      await controller.requestConfirmation();
      await controller.activateImmediately(category: 'Medical');

      expect(controller.state.status, EmergencyStatus.active);
      expect(controller.state.activeEvent, isNotNull);
      expect(controller.state.activeSession, isNotNull);
      expect(controller.state.assistantMessage, contains('Medical Emergency'));
    });

    test('endEmergency transitions active → sessionCompleted', () async {
      when(() => mockCreate(any())).thenAnswer((_) async => _mockEvent());

      final controller = _makeController(
        createUseCase: mockCreate,
        cancelUseCase: mockCancel,
        getRespondersUseCase: mockGetResponders,
        riskEvaluator: mockRiskEvaluator,
      );

      await controller.requestConfirmation();
      await controller.activateImmediately();

      expect(controller.state.status, EmergencyStatus.active);

      await controller.endEmergency();
      expect(controller.state.status, EmergencyStatus.sessionCompleted);
      expect(controller.state.activeSession!.endedAt, isNotNull);
    });

    test('resetToIdle returns to idle from any state', () async {
      final controller = _makeController(
        createUseCase: mockCreate,
        cancelUseCase: mockCancel,
        getRespondersUseCase: mockGetResponders,
        riskEvaluator: mockRiskEvaluator,
      );

      await controller.requestConfirmation();
      expect(controller.state.status, EmergencyStatus.awaitingConfirmation);

      controller.resetToIdle();
      expect(controller.state.status, EmergencyStatus.idle);
    });
  });
}
