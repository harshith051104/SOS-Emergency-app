/// timeline_generator_service.dart
///
/// Service managing the append-only timeline event log.

library;

import '../../domain/entities/timeline_entry.dart';

class TimelineGeneratorService {
  TimelineGeneratorService();

  final List<TimelineEntry> _entries = [];

  List<TimelineEntry> get entries => List.unmodifiable(_entries);

  /// Appends a new timeline entry to the append-only log.
  void append(TimelineEntry entry) {
    _entries.add(entry);
  }

  /// Appends multiple timeline entries.
  void appendAll(Iterable<TimelineEntry> newEntries) {
    _entries.addAll(newEntries);
  }

  /// Sets initial entries (used when restoring state after restart).
  void loadExisting(List<TimelineEntry> existing) {
    _entries.clear();
    _entries.addAll(existing);
  }

  /// Reset/clear timeline logs.
  void clear() {
    _entries.clear();
  }
}
