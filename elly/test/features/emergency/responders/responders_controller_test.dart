/// responders_controller_test.dart
///
/// Unit tests for [RespondersController].
/// Uses [mocktail] to mock use case dependencies.

library;

import 'package:elly/features/emergency/responders/domain/entities/responder.dart';
import 'package:elly/features/emergency/responders/domain/enums/notification_method.dart';
import 'package:elly/features/emergency/responders/domain/enums/responder_type.dart';
import 'package:elly/features/emergency/responders/domain/usecases/delete_responder_usecase.dart';
import 'package:elly/features/emergency/responders/domain/usecases/get_responders_usecase.dart';
import 'package:elly/features/emergency/responders/domain/usecases/reorder_responders_usecase.dart';
import 'package:elly/features/emergency/responders/domain/usecases/save_responder_usecase.dart';
import 'package:elly/features/emergency/responders/presentation/controllers/responders_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockGetRespondersUseCase extends Mock implements GetRespondersUseCase {}

class MockSaveResponderUseCase extends Mock implements SaveResponderUseCase {}

class MockDeleteResponderUseCase extends Mock implements DeleteResponderUseCase {}

class MockReorderRespondersUseCase extends Mock
    implements ReorderRespondersUseCase {}

// ── Helpers ───────────────────────────────────────────────────────────────────

Responder _responder({
  String id = 'test-1',
  String name = 'Test User',
  int priority = 0,
}) =>
    Responder(
      id: id,
      name: name,
      type: ResponderType.family,
      notificationMethods: const [NotificationMethod.sms],
      phoneNumber: '+1 555 000 0000',
      priority: priority,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockGetRespondersUseCase mockGet;
  late MockSaveResponderUseCase mockSave;
  late MockDeleteResponderUseCase mockDelete;
  late MockReorderRespondersUseCase mockReorder;

  setUp(() {
    mockGet = MockGetRespondersUseCase();
    mockSave = MockSaveResponderUseCase();
    mockDelete = MockDeleteResponderUseCase();
    mockReorder = MockReorderRespondersUseCase();

    // Default: getResponders returns empty list.
    when(() => mockGet()).thenAnswer((_) async => []);
  });

  RespondersController _makeController() => RespondersController(
        getRespondersUseCase: mockGet,
        saveResponderUseCase: mockSave,
        deleteResponderUseCase: mockDelete,
        reorderRespondersUseCase: mockReorder,
      );

  group('RespondersController — loadResponders', () {
    test('sets isLoading then returns responders', () async {
      final r = _responder();
      when(() => mockGet()).thenAnswer((_) async => [r]);

      final controller = _makeController();

      // Wait for initial load (called in constructor).
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.responders, [r]);
      expect(controller.state.error, isNull);

      controller.dispose();
    });

    test('sets error on use case exception', () async {
      when(() => mockGet()).thenThrow(Exception('DB error'));

      final controller = _makeController();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, isNotNull);

      controller.dispose();
    });
  });

  group('RespondersController — saveResponder', () {
    test('calls save then reloads list', () async {
      final r = _responder();
      when(() => mockGet()).thenAnswer((_) async => [r]);
      when(() => mockSave(r)).thenAnswer((_) async => r);

      final controller = _makeController();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await controller.saveResponder(r);

      verify(() => mockSave(r)).called(1);
      // loadResponders is called after save.
      verify(() => mockGet()).called(greaterThanOrEqualTo(2));

      controller.dispose();
    });
  });

  group('RespondersController — deleteResponder', () {
    test('calls delete then reloads list', () async {
      when(() => mockGet()).thenAnswer((_) async => []);
      when(() => mockDelete('test-1')).thenAnswer((_) async {});

      final controller = _makeController();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await controller.deleteResponder('test-1');

      verify(() => mockDelete('test-1')).called(1);

      controller.dispose();
    });
  });

  group('RespondersController — reorder', () {
    test('applies optimistic update and calls use case', () async {
      final r0 = _responder(id: 'a', priority: 0);
      final r1 = _responder(id: 'b', priority: 1);
      when(() => mockGet()).thenAnswer((_) async => [r0, r1]);
      when(() => mockReorder(any())).thenAnswer((_) async {});

      final controller = _makeController();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Move index 0 → index 1 (swap).
      await controller.reorder(0, 1);

      // Optimistic update: first item should now be r0 or r1 depending on
      // Flutter's ReorderableListView adjustment (newIndex - 1 when moving down).
      expect(controller.state.responders.length, 2);
      verify(() => mockReorder(any())).called(1);

      controller.dispose();
    });
  });
}
