/// assistant_test.dart
///
/// Unit tests verifying ELLY Live Voice Assistant brain, prioritisation,
/// deduplication, caching, and fallback policies.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:elly/features/emergency/assistant/domain/entities/voice_event.dart';
import 'package:elly/features/emergency/assistant/data/services/assistant_brain.dart';
import 'package:elly/features/emergency/assistant/data/services/voice_scheduler.dart';
import 'package:elly/features/emergency/assistant/data/services/conversation_policy_engine.dart';
import 'package:elly/features/emergency/assistant/data/services/speech_synthesis_service.dart';
import 'package:elly/features/emergency/assistant/data/services/conversation_manager.dart';
import 'package:elly/features/emergency/assistant/domain/entities/conversation_message.dart';

// ── Mock Classes ─────────────────────────────────────────────────────────────

class MockVoiceScheduler extends Mock implements VoiceScheduler {}
class MockConversationPolicyEngine extends Mock implements ConversationPolicyEngine {}
class MockSpeechSynthesisService extends Mock implements SpeechSynthesisService {}
class MockHttpClient extends Mock implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(VoiceEvent(
      id: '',
      text: '',
      priority: VoicePriority.standard,
      timestamp: DateTime.now(),
    ));
  });

  group('AssistantBrain Deduplication & Filtering —', () {
    late MockVoiceScheduler mockScheduler;
    late ConversationPolicyEngine policyEngine;
    late AssistantBrain brain;

    setUp(() {
      mockScheduler = MockVoiceScheduler();
      policyEngine = const ConversationPolicyEngine();
      brain = AssistantBrain(policyEngine: policyEngine, scheduler: mockScheduler);
      
      when(() => mockScheduler.queueEvent(any())).thenAnswer((_) async => {});
      when(() => mockScheduler.interrupt()).thenAnswer((_) async => {});
    });

    test('ignores identical location updates within 15 seconds', () {
      // First update

      brain.processLocationUpdate(address: '123 Safe St', accuracy: '5m');
      verify(() => mockScheduler.queueEvent(any())).called(1);

      // Duplicate immediate update
      brain.processLocationUpdate(address: '123 Safe St', accuracy: '5m');
      verifyNever(() => mockScheduler.queueEvent(any()));
    });

    test('fires battery warning only at specific thresholds (20%, 10%, 5%)', () {
      // 80% shouldn't fire
      brain.processBatteryUpdate(80);
      verifyNever(() => mockScheduler.queueEvent(any()));

      // 20% should fire
      brain.processBatteryUpdate(20);
      verify(() => mockScheduler.queueEvent(any())).called(1);

      // Duplicate 20% check shouldn't fire
      brain.processBatteryUpdate(19);
      verifyNever(() => mockScheduler.queueEvent(any()));

      // 10% should fire
      brain.processBatteryUpdate(10);
      verify(() => mockScheduler.queueEvent(any())).called(1);
    });
  });

  group('ConversationPolicyEngine Rules —', () {
    const policyEngine = ConversationPolicyEngine();

    test('detects sensitive topics correctly', () {
      expect(policyEngine.isSensitive('I was assaulted'), isTrue);
      expect(policyEngine.isSensitive('They want to murder me'), isTrue);
      expect(policyEngine.isSensitive('I am feeling dizzy'), isFalse);
    });

    test('returns custom offline fallback response based on trigger words', () {
      expect(
        policyEngine.getOfflineResponse('I am bleeding and hurt'),
        contains('medical profile'),
      );
      expect(
        policyEngine.getOfflineResponse('there is heavy smoke and fire'),
        contains('avoid inhaling smoke'),
      );
      expect(
        policyEngine.getOfflineResponse('cancel and stop'),
        contains('End Emergency'),
      );
    });
  });

  group('ConversationManager Compaction —', () {
    late ConversationManager manager;

    setUp(() {
      manager = ConversationManager();
    });

    test('compacts messages and updates running summary when count exceeds limit', () {
      // Add 9 messages
      for (int i = 0; i < 9; i++) {
        manager.addMessage(
          i % 2 == 0 ? MessageRole.user : MessageRole.assistant,
          'Message $i',
        );
      }

      // Assert that history got trimmed/compacted to 4 items
      expect(manager.messages.length, 4);
      expect(manager.summary, contains('Message 0'));
      expect(manager.summary, contains('Message 4'));
      // The last 4 messages should still be in active context window
      expect(manager.messages.first.text, 'Message 5');
      expect(manager.messages.last.text, 'Message 8');
    });
  });
}
