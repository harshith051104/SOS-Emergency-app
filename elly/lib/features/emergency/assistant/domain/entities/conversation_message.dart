/// conversation_message.dart
///
/// Represents a single conversation bubble between user and assistant.

library;

import 'package:equatable/equatable.dart';

enum MessageRole {
  user,
  assistant,
  system,
}

class ConversationMessage extends Equatable {
  const ConversationMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final MessageRole role;
  final String text;
  final DateTime timestamp;

  @override
  List<Object?> get props => [id, role, text, timestamp];
}
