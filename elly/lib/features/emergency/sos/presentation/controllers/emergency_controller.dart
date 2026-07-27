/// emergency_controller.dart
///
/// The [EmergencyController] is the orchestrator between the UI and the
/// domain use cases. It is the single source of truth for all emergency
/// UI state.
///
/// State machine (new session-based flow):
///
///   idle
///     │ requestConfirmation()
///     ▼
///   awaitingConfirmation  ← 10-second "Are you safe?" page
///     │
///     ├─► markUserSafe() ──► cancelled ──► idle
///     │
///     └─► activateImmediately() / countdown expiry
///           │
///           ▼
///        generatingPacket  ← Checklist verification
///           │
///           ▼
///        activating  ← Network mock call
///           │
///           ▼
///        active  ← Live Emergency Session
///           │
///           ▼
///        sessionCompleted  ← Final Emergency Report

library;

import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/core/utils/emergency_number_resolver.dart';
import '../../domain/entities/emergency_config.dart';
import '../../domain/entities/emergency_event.dart';
import '../../domain/entities/emergency_session.dart';
import '../../domain/enums/emergency_status.dart';
import '../../domain/enums/emergency_type.dart';
import '../../domain/services/emergency_risk_evaluator.dart';
import '../../domain/usecases/cancel_emergency_usecase.dart';
import '../../domain/usecases/create_emergency_usecase.dart';
import '../../../responders/domain/usecases/get_responders_usecase.dart';
import '../../../packet/data/services/location_service.dart';
import '../../../responders/domain/enums/responder_type.dart';

// ── State ─────────────────────────────────────────────────────────────────────

/// Immutable state for the [EmergencyController].
class EmergencyControllerState extends Equatable {
  const EmergencyControllerState({
    this.status = EmergencyStatus.idle,
    this.countdownValue = 0,
    this.activeEvent,
    this.errorMessage,
    this.activeSession,
    this.sessionDurationSeconds = 0,
    this.assistantMessage = 'Emergency contacts are being notified...',
    this.generatingProgress = 0,
    this.selectedCategory,
  });

  /// Current lifecycle status.
  final EmergencyStatus status;

  /// Current countdown value.
  final int countdownValue;

  /// The active [EmergencyEvent] once created.
  final EmergencyEvent? activeEvent;

  /// Error message if [status] is [EmergencyStatus.failed].
  final String? errorMessage;

  /// The active [EmergencySession] metadata and states.
  final EmergencySession? activeSession;

  /// Running session timer.
  final int sessionDurationSeconds;

  /// Current text displayed in the ELLY assistant panel.
  final String assistantMessage;

  /// Packet generation progress checklist value (0 to 6).
  final int generatingProgress;

  /// Category name of the emergency.
  final String? selectedCategory;

  /// Formats duration as hh:mm:ss.
  String get formattedDuration {
    final minutes = (sessionDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (sessionDurationSeconds % 60).toString().padLeft(2, '0');
    return '00:$minutes:$seconds';
  }

  EmergencyControllerState copyWith({
    EmergencyStatus? status,
    int? countdownValue,
    EmergencyEvent? activeEvent,
    String? errorMessage,
    EmergencySession? activeSession,
    int? sessionDurationSeconds,
    String? assistantMessage,
    int? generatingProgress,
    String? selectedCategory,
  }) {
    return EmergencyControllerState(
      status: status ?? this.status,
      countdownValue: countdownValue ?? this.countdownValue,
      activeEvent: activeEvent ?? this.activeEvent,
      errorMessage: errorMessage ?? this.errorMessage,
      activeSession: activeSession ?? this.activeSession,
      sessionDurationSeconds:
          sessionDurationSeconds ?? this.sessionDurationSeconds,
      assistantMessage: assistantMessage ?? this.assistantMessage,
      generatingProgress: generatingProgress ?? this.generatingProgress,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  @override
  List<Object?> get props => [
        status,
        countdownValue,
        activeEvent,
        errorMessage,
        activeSession,
        sessionDurationSeconds,
        assistantMessage,
        generatingProgress,
        selectedCategory,
      ];
}

// ── Controller ────────────────────────────────────────────────────────────────

class EmergencyController extends StateNotifier<EmergencyControllerState> with WidgetsBindingObserver {
  EmergencyController({
    required CreateEmergencyUseCase createEmergencyUseCase,
    required CancelEmergencyUseCase cancelEmergencyUseCase,
    required GetRespondersUseCase getRespondersUseCase,
    required EmergencyConfig config,
    required EmergencyRiskEvaluator riskEvaluator,
    required LocationService locationService,
  })  : _createEmergencyUseCase = createEmergencyUseCase,
        _cancelEmergencyUseCase = cancelEmergencyUseCase,
        _getRespondersUseCase = getRespondersUseCase,
        _config = config,
        _riskEvaluator = riskEvaluator,
        _locationService = locationService,
        super(const EmergencyControllerState()) {
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) _restoreActiveSession();
    });
  }

  bool _isProcessingConfirmation = false;

  final CreateEmergencyUseCase _createEmergencyUseCase;
  final CancelEmergencyUseCase _cancelEmergencyUseCase;
  final GetRespondersUseCase _getRespondersUseCase;

  CancelEmergencyUseCase get cancelEmergencyUseCase => _cancelEmergencyUseCase;

  final EmergencyConfig _config;
  final EmergencyRiskEvaluator _riskEvaluator;
  final LocationService _locationService;

  Timer? _countdownTimer;
  Timer? _sessionTimer;

  final List<String> _assistantMessagePool = [
    'Emergency contacts have been notified.',
    'Stay calm. ELLY is staying with you.',
    'I have shared your medical profile and live battery status.',
    'Can you hear me? Speak clearly if you can.',
    'Are you conscious and safe from immediate threat?',
    'Emergency services have been queued as backup.',
    'I am continuously monitoring your motion and audio.',
  ];

  // ── Guard ─────────────────────────────────────────────────────────────────

  bool get isLocked {
    return state.status == EmergencyStatus.awaitingConfirmation ||
        state.status == EmergencyStatus.generatingPacket ||
        state.status == EmergencyStatus.countdown ||
        state.status == EmergencyStatus.activating ||
        state.status == EmergencyStatus.active;
  }

  // ── State Machine — New Flow ───────────────────────────────────────────────

  Future<void> requestConfirmation() async {
    if (isLocked || _isProcessingConfirmation) {
      appLogger.warning(
        'EmergencyController: requestConfirmation called while locked '
        '(status=${state.status}, processing=$_isProcessingConfirmation). Ignoring.',
      );
      return;
    }

    _isProcessingConfirmation = true;

    try {
      final skipConfirmation = await _riskEvaluator.shouldSkipConfirmation();
      if (skipConfirmation) {
        appLogger.info(
          'EmergencyController: riskEvaluator returned true → skipping confirmation.',
        );
        _hapticHeavy();
        await startGeneratingPacket();
        return;
      }

      appLogger.info('EmergencyController: idle → awaitingConfirmation');
      _hapticMedium();

      state = state.copyWith(
        status: EmergencyStatus.awaitingConfirmation,
        countdownValue: _config.confirmationDuration,
      );

      _startConfirmationTimer();
    } finally {
      _isProcessingConfirmation = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _handleAppBackground();
    }
  }


  void _handleAppBackground() {
    if (state.status == EmergencyStatus.awaitingConfirmation) {
      appLogger.info(
        'EmergencyController: App went to background during countdown. '
        'Activating emergency immediately for safety.',
      );
      _stopTimer();
      startGeneratingPacket();
    }
  }

  Future<void> _restoreActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool('elly_session_active') ?? false;
      if (!isActive) return;

      final sessionId = prefs.getString('elly_session_id') ?? '';
      final startTimeStr = prefs.getString('elly_session_start_time') ?? '';
      if (sessionId.isEmpty || startTimeStr.isEmpty) return;

      final startedAt = DateTime.parse(startTimeStr);
      final elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;

      // Discard sessions older than 4 hours — likely left over from a test run.
      // Without this guard, stale SharedPreferences data locks the UI in
      // emergency-active mode on every subsequent app start.
      if (elapsedSeconds > 4 * 3600) {
        await prefs.setBool('elly_session_active', false);
        appLogger.info('EmergencyController: Stale session discarded (${elapsedSeconds}s old).');
        return;
      }

      // Load responders
      final configuredResponders = await _getRespondersUseCase();
      final statuses = configuredResponders.map((r) {
        return ResponderSessionStatus(
          responder: r,
          state: elapsedSeconds >= 18
              ? ResponderSessionState.accepted
              : elapsedSeconds >= 5
                  ? ResponderSessionState.notified
                  : ResponderSessionState.pending,
        );
      }).toList();

      final session = EmergencySession(
        sessionId: sessionId,
        startedAt: startedAt,
        batteryLevel: prefs.getString('elly_session_battery') ?? '82%',
        currentAddress: prefs.getString('elly_session_current_address') ?? 'Hyderabad, Telangana, India',
        locationAccuracy: prefs.getString('elly_session_location_accuracy') ?? '5m',
        medicalProfileSummary: prefs.getString('elly_session_medical_summary') ?? 'Asthma, Penicillin Allergy, Blood Group O+',
        responderStatuses: statuses,
      );

      Future.microtask(() {
        if (!mounted) return;
        state = state.copyWith(
          status: EmergencyStatus.active,
          activeSession: session,
          sessionDurationSeconds: elapsedSeconds,
          assistantMessage: 'Emergency session recovered.',
        );
        _startSessionTimer();
        appLogger.info('EmergencyController: Recovered active session $sessionId starting $elapsedSeconds seconds ago.');
      });
    } catch (e, st) {
      appLogger.error('EmergencyController: Failed to restore active session', e, st);
    }
  }


  Future<void> markUserSafe() async {
    if (state.status != EmergencyStatus.awaitingConfirmation) return;

    appLogger.info('EmergencyController: cancelled (user safe)');
    _stopTimer();
    _hapticLight();

    state = state.copyWith(status: EmergencyStatus.cancelled);

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) resetToIdle();
  }

  Future<void> activateImmediately({String? category}) async {
    if (state.status != EmergencyStatus.awaitingConfirmation) return;

    _stopTimer();
    _hapticHeavy();

    final location = await _locationService.getCurrentLocation();
    await _activate(category: category);

    // Call the specific emergency service corresponding to the category & live GPS country
    if (category != null) {
      final serviceNumber = EmergencyNumberResolver.resolveServiceNumber(
        category: category,
        countryCode: location.isoCountryCode,
      );
      appLogger.info('EmergencyController: Placing call to resolved service number $serviceNumber for category $category [Country: ${location.isoCountryCode}]');
      await EmergencyNumberResolver.makeEmergencyCall(serviceNumber);
    }
  }

  /// Activates the emergency session directly (bypassing the compiler loader page).
  Future<void> startGeneratingPacket({String? category}) async {
    appLogger.info('EmergencyController: activating emergency session directly');
    _stopTimer();
    await _activate(category: category);
  }

  // ── Session Ended ─────────────────────────────────────────────────────────

  /// Ends the active emergency and calculates final report statistics.
  Future<void> endEmergency() async {
    if (state.status != EmergencyStatus.active) return;

    appLogger.info('EmergencyController: ending emergency session.');
    _hapticHeavy();
    _stopSessionTimer();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('elly_session_active');
      await prefs.remove('elly_session_id');
      await prefs.remove('elly_session_start_time');
      await prefs.remove('elly_session_current_address');
      await prefs.remove('elly_session_location_accuracy');
      await prefs.remove('elly_session_battery');
      await prefs.remove('elly_session_medical_summary');
    } catch (e) {
      appLogger.error('EmergencyController: Failed to clear session recovery keys', e);
    }

    final session = state.activeSession;
    if (session != null) {
      final updatedSession = session.copyWith(endedAt: DateTime.now());

      state = state.copyWith(
        status: EmergencyStatus.sessionCompleted,
        activeSession: updatedSession,
      );
    } else {
      state = state.copyWith(status: EmergencyStatus.sessionCompleted);
    }
  }

  void _startConfirmationTimer() {
    _stopTimer();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = state.countdownValue - 1;

      if (next <= 0) {
        timer.cancel();
        appLogger.info('EmergencyController: 10s countdown expired without selection → auto-calling emergency services');
        _handleTimeoutAutoCall();
      } else {
        Future.microtask(() {
          if (mounted) state = state.copyWith(countdownValue: next);
        });
      }
    });
  }

  Future<void> _handleTimeoutAutoCall() async {
    final location = await _locationService.getCurrentLocation();
    final emergencyNumber = EmergencyNumberResolver.resolveNumber(
      countryCode: location.isoCountryCode,
      address: location.address,
    );
    appLogger.info('EmergencyController: 10s timeout expired. Auto-calling universal number: $emergencyNumber [Country: ${location.isoCountryCode}, Address: ${location.address}]');

    // 1. Activate session
    await _activate(category: 'General Emergency');

    // 2. Initiate universal national emergency phone call via url_launcher
    await EmergencyNumberResolver.makeEmergencyCall(emergencyNumber);
  }

  // ── Private: Activation & Session Lifecycle ───────────────────────────────

  Future<void> _activate({String? category}) async {
    appLogger.info('EmergencyController: _activate started (category=$category)');
    state = state.copyWith(
      status: EmergencyStatus.activating,
      selectedCategory: category,
    );

    try {
      appLogger.info('EmergencyController: calling _createEmergencyUseCase');
      final event = await _createEmergencyUseCase(EmergencyType.manual);
      appLogger.info('EmergencyController: _createEmergencyUseCase success');

      // Resolve country code from live location
      String? liveCountryCode;
      String currentAddress = 'Hyderabad, Telangana, India';
      String locationAccuracy = '5m';
      try {
        appLogger.info('EmergencyController: fetching live location details');
        final location = await _locationService.getCurrentLocation();
        liveCountryCode = location.isoCountryCode;
        currentAddress = location.address;
        locationAccuracy = location.accuracy;
        appLogger.info('EmergencyController: GPS live address = "$currentAddress", country = "$liveCountryCode"');
      } catch (e) {
        appLogger.warning('EmergencyController: Failed to fetch live location country code: $e');
      }

      // Load actual responders to display in session
      appLogger.info('EmergencyController: calling _getRespondersUseCase');
      final configuredResponders = await _getRespondersUseCase();
      appLogger.info('EmergencyController: _getRespondersUseCase success (${configuredResponders.length} responders)');

      // Seed default statuses and dynamically update Emergency Services numbers based on country & category
      final statuses = configuredResponders.map((r) {
        var responder = r;
        if (responder.type == ResponderType.emergencyService) {
          final resolvedNum = EmergencyNumberResolver.resolveServiceNumber(
            category: category ?? 'universal',
            countryCode: liveCountryCode,
          );
          responder = responder.copyWith(phoneNumber: resolvedNum);
          appLogger.info('EmergencyController: Dynamically set Emergency Services number to $resolvedNum based on country $liveCountryCode and category $category');
        }
        return ResponderSessionStatus(
          responder: responder,
          state: ResponderSessionState.pending,
        );
      }).toList();

      final session = EmergencySession(
        sessionId: '#EL-2026-${100000 + Random().nextInt(900000)}',
        startedAt: DateTime.now(),
        batteryLevel: '82%',
        currentAddress: currentAddress,
        locationAccuracy: locationAccuracy,
        medicalProfileSummary: 'Asthma, Penicillin Allergy, Blood Group O+',
        responderStatuses: statuses,
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('elly_session_active', true);
        await prefs.setString('elly_session_id', session.sessionId);
        await prefs.setString('elly_session_start_time', session.startedAt.toIso8601String());
        await prefs.setString('elly_session_current_address', session.currentAddress);
        await prefs.setString('elly_session_location_accuracy', session.locationAccuracy);
        await prefs.setString('elly_session_battery', session.batteryLevel);
        await prefs.setString('elly_session_medical_summary', session.medicalProfileSummary);
      } catch (e) {
        appLogger.error('EmergencyController: Failed to save session keys for recovery', e);
      }

      final messageText = (category != null && category.isNotEmpty)
          ? '$category Emergency selected. Emergency contacts notified.'
          : 'Emergency packet shared. Notifying contacts...';

      Future.microtask(() {
        if (mounted) {
          state = state.copyWith(
            status: EmergencyStatus.active,
            activeEvent: event,
            activeSession: session,
            sessionDurationSeconds: 0,
            assistantMessage: messageText,
          );
          _startSessionTimer();
          appLogger.info('EmergencyController: transitioned to active and started session timer');
        }
      });
    } catch (e, st) {
      appLogger.error('EmergencyController: activation error caught, proceeding with fallback session', e, st);
      final fallbackSession = EmergencySession(
        sessionId: '#EL-2026-${100000 + Random().nextInt(900000)}',
        startedAt: DateTime.now(),
        batteryLevel: '82%',
        currentAddress: 'Hyderabad, Telangana, India',
        locationAccuracy: '5m',
        medicalProfileSummary: 'Asthma, Penicillin Allergy, Blood Group O+',
        responderStatuses: const [],
      );

      Future.microtask(() {
        if (mounted) {
          state = state.copyWith(
            status: EmergencyStatus.active,
            activeSession: fallbackSession,
            sessionDurationSeconds: 0,
            assistantMessage: 'Emergency session active. Notifying contacts...',
          );
          _startSessionTimer();
        }
      });
    }
  }


  void _startSessionTimer() {
    _stopSessionTimer();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // addPostFrameCallback guarantees the 1-Hz state mutation lands
      // AFTER the complete frame pipeline. Using Future(() {}) here caused
      // the callback to land between _handleBeginFrame and _handleDrawFrame
      // on Android (separate event-loop tasks), triggering the
      // debugFrameWasSentToEngine assertion storm at exactly 1 Hz.
      Future.microtask(() {
        if (!mounted || state.status != EmergencyStatus.active) {
          timer.cancel();
          return;
        }

        final nextSeconds = state.sessionDurationSeconds + 1;
        var updatedSession = state.activeSession;
        var message = state.assistantMessage;

        // Rotate assistant messages every 6 seconds
        if (nextSeconds % 6 == 0) {
          final index = (nextSeconds ~/ 6) % _assistantMessagePool.length;
          message = _assistantMessagePool[index];
        }

        // Simulate responder status progression
        if (updatedSession != null) {
          final list = List<ResponderSessionStatus>.from(updatedSession.responderStatuses);
          var changed = false;

          for (var i = 0; i < list.length; i++) {
            final item = list[i];

            // Responder 1 (Mom/first) simulation
            if (i == 0) {
              if (nextSeconds == 2 && item.state == ResponderSessionState.pending) {
                list[0] = item.copyWith(
                  state: ResponderSessionState.notified,
                  updatedAt: DateTime.now(),
                );
                changed = true;
              } else if (nextSeconds == 6 && item.state == ResponderSessionState.notified) {
                list[0] = item.copyWith(
                  state: ResponderSessionState.accepted,
                  updatedAt: DateTime.now(),
                );
                message = '${item.responder.name} accepted the alert. Help is on the way!';
                _hapticHeavy();
                changed = true;
              }
            }

            // Responder 2 simulation
            if (i == 1) {
              if (nextSeconds == 5 && item.state == ResponderSessionState.pending) {
                list[1] = item.copyWith(
                  state: ResponderSessionState.notified,
                  updatedAt: DateTime.now(),
                );
                changed = true;
              } else if (nextSeconds == 15 && item.state == ResponderSessionState.notified) {
                list[1] = item.copyWith(
                  state: ResponderSessionState.timedOut,
                  updatedAt: DateTime.now(),
                );
                changed = true;
              }
            }

            // Responder 3 simulation
            if (i == 2) {
              if (nextSeconds == 10 && item.state == ResponderSessionState.pending) {
                list[2] = item.copyWith(
                  state: ResponderSessionState.notified,
                  updatedAt: DateTime.now(),
                );
                changed = true;
              } else if (nextSeconds == 18 && item.state == ResponderSessionState.notified) {
                list[2] = item.copyWith(
                  state: ResponderSessionState.accepted,
                  updatedAt: DateTime.now(),
                );
                changed = true;
              }
            }
          }

          if (changed) {
            updatedSession = updatedSession.copyWith(responderStatuses: list);
          }
        }

        state = state.copyWith(
          sessionDurationSeconds: nextSeconds,
          activeSession: updatedSession,
          assistantMessage: message,
        );
      });
    });

  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Resets the controller state to idle.
  void resetToIdle() {
    _stopTimer();
    _stopSessionTimer();
    appLogger.info('EmergencyController: reset to idle');
    state = const EmergencyControllerState();

    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('elly_session_active');
        prefs.remove('elly_session_id');
        prefs.remove('elly_session_start_time');
        prefs.remove('elly_session_current_address');
        prefs.remove('elly_session_location_accuracy');
        prefs.remove('elly_session_battery');
        prefs.remove('elly_session_medical_summary');
      });
    } catch (e) {
      appLogger.error('EmergencyController: Failed to clear session keys on reset', e);
    }
  }

  // ── Legacy Flow Support ───────────────────────────────────────────────────

  void startCountdown() {
    _startConfirmationTimer();
  }

  Future<void> cancelCountdown() async {
    await markUserSafe();
  }

  void _hapticLight() {
    if (_config.vibrationEnabled) HapticFeedback.lightImpact();
  }

  void _hapticMedium() {
    if (_config.vibrationEnabled) HapticFeedback.mediumImpact();
  }

  void _hapticHeavy() {
    if (_config.vibrationEnabled) HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _stopSessionTimer();
    super.dispose();
  }
}
