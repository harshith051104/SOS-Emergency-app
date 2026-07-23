/// voice_event.dart
///
/// Model representing a queued speech request with priority level and text payload.
/// [audioPath] carries the pre-synthesized local audio file path so the scheduler
/// can play it directly without a second API call.

library;

import 'package:equatable/equatable.dart';

enum VoicePriority {
  /// Priority 1: Critical system warnings (Battery low, GPS lost).
  critical(1),

  /// Priority 2: General status updates (Packet ready, Location updated).
  standard(2),

  /// Priority 3: Interactive dialogue responses.
  dialogue(3);

  const VoicePriority(this.value);
  final int value;
}

class VoiceEvent extends Equatable {
  const VoiceEvent({
    required this.id,
    required this.text,
    required this.priority,
    required this.timestamp,
    this.isInterrupting = false,
    this.audioPath,
  });

  final String id;
  final String text;
  final VoicePriority priority;
  final DateTime timestamp;
  final bool isInterrupting;

  /// Pre-synthesized local audio file path. When non-null, [_onSpeakEvent]
  /// plays this file directly instead of calling the TTS API again.
  final String? audioPath;

  @override
  List<Object?> get props => [id, text, priority, timestamp, isInterrupting, audioPath];
}
