/// assistant_state.dart
///
/// State machine states representing the current phase of the
/// ELLY Voice Assistant.

library;

enum AssistantState {
  /// Services are configuring, checking permissions, etc.
  initializing,

  /// Idle state, waiting for user speech trigger or system event.
  idle,

  /// Active microphone listening.
  listening,

  /// Transcribing captured audio bytes to text (e.g. Whisper API).
  transcribing,

  /// Groq LLM processing/generating reply tokens.
  thinking,

  /// Synthesizing text to WAV and playing audio aloud (Orpheus).
  speaking,

  /// Assistant is muted by user.
  muted,

  /// Processing is temporarily suspended.
  paused,

  /// Active speech output was halted due to user barge-in.
  interrupted,

  /// An unrecoverable sub-system or API error occurred.
  error,
}
