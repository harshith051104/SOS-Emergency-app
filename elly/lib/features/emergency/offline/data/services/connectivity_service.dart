/// connectivity_service.dart
///
/// Hardware network & connectivity service monitoring Wi-Fi, Mobile Data, Airplane Mode,
/// and connection restoration.

library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/offline/domain/entities/connectivity_state.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        _stateController = StreamController<ConnectivityState>.broadcast();

  final Connectivity _connectivity;
  final StreamController<ConnectivityState> _stateController;
  StreamSubscription? _subscription;
  ConnectivityState _currentState = ConnectivityState.online;

  ConnectivityState get currentState => _currentState;
  Stream<ConnectivityState> get onConnectivityStateChanged => _stateController.stream;

  Future<void> initialize() async {
    appLogger.info('ConnectivityService: Initializing hardware network monitor...');
    try {
      final results = await _connectivity.checkConnectivity();
      _currentState = _mapResultsToState(results);
      _emitState(_currentState);
    } catch (e, st) {
      appLogger.error('ConnectivityService: Failed checking initial connectivity', e, st);
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final newState = _mapResultsToState(results);
      if (newState != _currentState) {
        appLogger.info('ConnectivityService: Hardware network state changed: $_currentState ➔ $newState');
        _currentState = newState;
        _emitState(_currentState);
      }
    });
  }

  ConnectivityState _mapResultsToState(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityState.offline;
    }

    if (results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityState.online;
    }

    return ConnectivityState.limited;
  }

  void _emitState(ConnectivityState state) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _stateController.close();
  }
}
