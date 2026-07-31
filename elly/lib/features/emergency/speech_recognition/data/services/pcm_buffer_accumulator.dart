/// pcm_buffer_accumulator.dart
///
/// Accumulates incoming 16kHz PCM audio frame chunks during an active speech utterance.

library;

import 'dart:typed_data';

class PcmBufferAccumulator {
  final List<Uint8List> _chunks = [];
  int _totalBytes = 0;
  DateTime? _startedAt;

  bool get isEmpty => _chunks.isEmpty;
  int get totalBytes => _totalBytes;
  DateTime? get startedAt => _startedAt;

  void start() {
    clear();
    _startedAt = DateTime.now();
  }

  void appendFrame(Uint8List frame) {
    if (frame.isEmpty) return;
    _startedAt ??= DateTime.now();
    _chunks.add(frame);
    _totalBytes += frame.length;
  }

  Uint8List mergeAndClear() {
    if (_totalBytes == 0) return Uint8List(0);

    final merged = Uint8List(_totalBytes);
    var offset = 0;
    for (final chunk in _chunks) {
      merged.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    clear();
    return merged;
  }

  void clear() {
    _chunks.clear();
    _totalBytes = 0;
    _startedAt = null;
  }
}
