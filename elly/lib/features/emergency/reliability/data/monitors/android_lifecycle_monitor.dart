/// android_lifecycle_monitor.dart
///
/// Monitor observing App Lifecycle (Resumed, Paused, Detached) and Doze Mode state.

library;

import 'dart:async';
import 'package:flutter/widgets.dart';

enum AppExecutionState {
  foreground,
  background,
  detached,
}

class AndroidLifecycleMonitor with WidgetsBindingObserver {
  AndroidLifecycleMonitor() {
    WidgetsBinding.instance.addObserver(this);
  }

  final _stateController = StreamController<AppExecutionState>.broadcast();
  AppExecutionState _currentState = AppExecutionState.foreground;

  Stream<AppExecutionState> get stateStream => _stateController.stream;
  AppExecutionState get currentState => _currentState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _currentState = AppExecutionState.foreground;
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _currentState = AppExecutionState.background;
        break;
      case AppLifecycleState.detached:
        _currentState = AppExecutionState.detached;
        break;
    }
    if (!_stateController.isClosed) {
      Future<void>(() {
        if (!_stateController.isClosed) _stateController.add(_currentState);
      });
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateController.close();
  }
}
