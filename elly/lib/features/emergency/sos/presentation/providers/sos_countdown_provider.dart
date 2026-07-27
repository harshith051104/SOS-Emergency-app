/// sos_countdown_provider.dart
///
/// Riverpod providers exposing the SOS Countdown Engine, state, and event stream.

library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sos_countdown_state.dart';
import '../../data/services/sos_countdown_engine.dart';


final sosCountdownEngineProvider = Provider<SosCountdownEngine>((ref) {
  final engine = SosCountdownEngine();
  ref.onDispose(() => engine.dispose());
  return engine;
});

final sosCountdownStateProvider =
    StateNotifierProvider<SosCountdownNotifier, SosCountdownStateModel>((ref) {
  final engine = ref.watch(sosCountdownEngineProvider);
  return SosCountdownNotifier(engine);
});

final sosCountdownEventStreamProvider = StreamProvider<SosCountdownEvent>((ref) {
  final engine = ref.watch(sosCountdownEngineProvider);
  return engine.eventStream;
});

class SosCountdownNotifier extends StateNotifier<SosCountdownStateModel> {
  SosCountdownNotifier(this._engine) : super(const SosCountdownStateModel()) {
    _streamSub = _engine.eventStream.listen((event) {
      if (mounted) {
        state = _engine.state;
      }
    });
  }

  final SosCountdownEngine _engine;
  late final StreamSubscription<SosCountdownEvent> _streamSub;

  void startCountdown({String source = 'MANUAL SOS', int durationSeconds = 10}) {
    _engine.startCountdown(source: source, durationSeconds: durationSeconds);
    state = _engine.state;
  }

  void cancelCountdown() {
    _engine.cancelCountdown();
    state = _engine.state;
  }

  void resetToIdle() {
    _engine.resetToIdle();
    state = _engine.state;
  }

  @override
  void dispose() {
    _streamSub.cancel();
    super.dispose();
  }
}
