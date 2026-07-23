/// conversation_policy_engine.dart
///
/// Implements deterministic conversation rules, sensitive topic filtering,
/// and offline fallback response resolution.

library;

import 'package:elly/core/utils/app_logger.dart';

class ConversationPolicyEngine {
  const ConversationPolicyEngine();

  /// Determines if the user input contains sensitive triggers (assault, violence, self-harm).
  bool isSensitive(String text) {
    final clean = text.toLowerCase();
    return clean.contains('assault') ||
        clean.contains('rape') ||
        clean.contains('murder') ||
        clean.contains('kill') ||
        clean.contains('suicide') ||
        clean.contains('cut myself') ||
        clean.contains('abuse') ||
        clean.contains('fight') ||
        clean.contains('attacked');
  }

  /// Returns a safe fallback instruction for sensitive inputs, bypassing LLM generation.
  String getSensitiveSafetyResponse() {
    return 'Your safety is the absolute priority. If you can, move to a secure location immediately. I have alerted emergency responders.';
  }

  /// Determines the local fallback response if the network/LLM is offline, based on keywords.
  String getOfflineResponse(String userInput) {
    final clean = userInput.toLowerCase();
    appLogger.info('ConversationPolicyEngine: Resolving offline fallback response for: "$clean"');

    if (clean.contains('hurt') || clean.contains('bleed') || clean.contains('pain') || clean.contains('medical')) {
      return "I'm offline, but your medical profile is active. Sit down, try to keep pressure on any wound, and rest.";
    }
    
    if (clean.contains('fire') || clean.contains('smoke') || clean.contains('burn')) {
      return "I'm offline. Get low, avoid inhaling smoke, and get out of the building safely right away.";
    }

    if (clean.contains('scared') || clean.contains('anxious') || clean.contains('panic') || clean.contains('afraid')) {
      return "Take one slow breath with me. Breathe in... and out. You are not alone, I am staying with you.";
    }

    if (clean.contains('safe') || clean.contains('stop') || clean.contains('cancel')) {
      return "You can safely end this session by tapping the End Emergency button at the top right.";
    }

    return "I am offline, but I am staying with you. Move to a secure location and keep your phone unlocked.";
  }
}
