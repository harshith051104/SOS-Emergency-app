/// conversation_manager.dart
///
/// Manages conversation history, memory compaction, and context window summary blocks.

library;

import 'package:uuid/uuid.dart';
import '../../domain/entities/conversation_message.dart';

class ConversationManager {
  ConversationManager({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  final List<ConversationMessage> _messages = [];
  String _summary = '';

  List<ConversationMessage> get messages => List.unmodifiable(_messages);
  String get summary => _summary;

  /// Adds a new message and automatically triggers history compaction if it grows too large.
  void addMessage(MessageRole role, String text) {
    _messages.add(ConversationMessage(
      id: _uuid.v4(),
      role: role,
      text: text,
      timestamp: DateTime.now(),
    ));

    _compactHistoryIfNeeded();
  }

  /// Compacts history by shifting older logs into the running summary,
  /// preserving only the last 4 messages in the active context window.
  void _compactHistoryIfNeeded() {
    if (_messages.length <= 8) return;

    // We take the oldest messages to merge into the summary
    final messagesToSummarize = _messages.sublist(0, _messages.length - 4);
    
    final summaryBuffer = StringBuffer(_summary);
    if (_summary.isNotEmpty) {
      summaryBuffer.write('\n');
    }

    for (final msg in messagesToSummarize) {
      final roleLabel = msg.role == MessageRole.user ? 'User' : 'ELLY';
      summaryBuffer.write('$roleLabel: "${msg.text}"\n');
    }

    _summary = summaryBuffer.toString();
    
    // Retain only the last 4 messages in history
    _messages.removeRange(0, _messages.length - 4);
  }

  /// Clears the history state.
  void clear() {
    _messages.clear();
    _summary = '';
  }
}
