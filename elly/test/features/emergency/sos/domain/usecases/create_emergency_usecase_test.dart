/// create_emergency_usecase_test.dart
///
/// Unit tests for [CreateEmergencyUseCase].

library;

import 'package:elly/features/emergency/sos/domain/entities/emergency_event.dart';
import 'package:elly/features/emergency/sos/domain/enums/emergency_status.dart';
import 'package:elly/features/emergency/sos/domain/enums/emergency_type.dart';
import 'package:elly/features/emergency/sos/domain/repositories/emergency_repository.dart';
import 'package:elly/features/emergency/sos/domain/usecases/create_emergency_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmergencyRepository extends Mock implements EmergencyRepository {}

void main() {
  late MockEmergencyRepository mockRepository;
  late CreateEmergencyUseCase useCase;

  setUpAll(() {
    registerFallbackValue(EmergencyType.manual);
  });

  setUp(() {
    mockRepository = MockEmergencyRepository();
    useCase = CreateEmergencyUseCase(mockRepository);
  });

  final testEvent = EmergencyEvent(
    id: 'test-id',
    type: EmergencyType.manual,
    status: EmergencyStatus.active,
    createdAt: DateTime(2024),
    activatedAt: DateTime(2024),
  );

  group('CreateEmergencyUseCase —', () {
    test('calls repository.createEmergency with correct type', () async {
      when(() => mockRepository.createEmergency(any()))
          .thenAnswer((_) async => testEvent);

      final result = await useCase(EmergencyType.manual);

      expect(result, testEvent);
      verify(() => mockRepository.createEmergency(EmergencyType.manual))
          .called(1);
    });

    test('propagates repository exceptions', () async {
      when(() => mockRepository.createEmergency(any()))
          .thenThrow(Exception('Connection error'));

      expect(
        () => useCase(EmergencyType.manual),
        throwsA(isA<Exception>()),
      );
    });
  });
}
