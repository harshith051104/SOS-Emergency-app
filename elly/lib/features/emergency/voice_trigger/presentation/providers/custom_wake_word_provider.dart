/// custom_wake_word_provider.dart
///
/// Riverpod StateNotifier managing custom user emergency wake words / code words.
/// Persists custom words using SharedPreferences and provides them to the Intent Detector.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kCustomWakeWordsKey = 'elly_custom_wake_words_v1';

/// Built-in standard wake words displayed in the UI.
const List<String> kDefaultWakeWords = [
  'Help me',
  'Emergency',
  'SOS',
  'Save me',
  'Call 112',
  'I can\'t breathe',
  'Oh my god',
  'Don\'t touch me',
  'Please leave me alone',
  'I can\'t survive',
  'Police',
  'Ambulance',
];

class CustomWakeWordsNotifier extends StateNotifier<List<String>> {
  CustomWakeWordsNotifier() : super([]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_kCustomWakeWordsKey);
      if (saved != null) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<bool> addWakeWord(String word) async {
    final trimmed = word.trim().toLowerCase();
    if (trimmed.isEmpty) return false;

    // Check duplicate
    if (state.any((w) => w.toLowerCase() == trimmed) ||
        kDefaultWakeWords.any((w) => w.toLowerCase() == trimmed)) {
      return false;
    }

    final updated = [...state, word.trim()];
    state = updated;
    await _saveToPrefs(updated);
    return true;
  }

  Future<void> removeWakeWord(String word) async {
    final updated = state.where((w) => w.toLowerCase() != word.toLowerCase()).toList();
    state = updated;
    await _saveToPrefs(updated);
  }

  Future<void> _saveToPrefs(List<String> words) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kCustomWakeWordsKey, words);
    } catch (_) {}
  }
}

final customWakeWordsProvider = StateNotifierProvider<CustomWakeWordsNotifier, List<String>>((ref) {
  return CustomWakeWordsNotifier();
});
