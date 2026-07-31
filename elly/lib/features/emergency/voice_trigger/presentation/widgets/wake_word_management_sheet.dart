/// wake_word_management_sheet.dart
///
/// Modal bottom sheet displaying default Voice Trigger wake words
/// and allowing users to add/manage custom emergency code words.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/custom_wake_word_provider.dart';

class WakeWordManagementSheet extends ConsumerStatefulWidget {
  const WakeWordManagementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WakeWordManagementSheet(),
    );
  }

  @override
  ConsumerState<WakeWordManagementSheet> createState() => _WakeWordManagementSheetState();
}

class _WakeWordManagementSheetState extends ConsumerState<WakeWordManagementSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addCustomWord() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final success = await ref.read(customWakeWordsProvider.notifier).addWakeWord(text);
    if (success) {
      _controller.clear();
      setState(() => _errorText = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added custom emergency code word: "$text"'),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        _errorText = 'Word already exists in wake word list';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customWords = ref.watch(customWakeWordsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF9333EA), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Trigger Wake Words',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Voice commands that trigger instant 10s SOS Alert',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Add Custom Word Form
            const Text(
              'Add Custom Emergency Code Word',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. "Red Sky", "Code Alpha"',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      errorText: _errorText,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    onSubmitted: (_) => _addCustomWord(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addCustomWord,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Custom Words Section (if any)
            if (customWords.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text(
                    'Custom Emergency Code Words (${customWords.length})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: customWords.map((word) {
                  return Chip(
                    backgroundColor: const Color(0xFFFEF3C7),
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                    avatar: const Icon(Icons.shield_rounded, size: 14, color: Color(0xFFD97706)),
                    label: Text(
                      word,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E)),
                    ),
                    deleteIcon: const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFFD97706)),
                    onDeleted: () {
                      ref.read(customWakeWordsProvider.notifier).removeWakeWord(word);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Default Built-in Wake Words Section
            const Text(
              'System Pre-set Wake Words',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kDefaultWakeWords.map((word) {
                return Chip(
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  label: Text(
                    '"$word"',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
