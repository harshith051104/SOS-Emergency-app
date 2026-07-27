/// assistant_providers.dart
///
/// Riverpod provider definitions for the Voice Assistant feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the secure Groq API key injected via build args or environment.
final groqApiKeyProvider = Provider<String>((ref) {
  return const String.fromEnvironment('GROQ_API_KEY');
});
