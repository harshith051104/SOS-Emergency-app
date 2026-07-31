/// speaker_verification_controller.dart
///
/// Master presentation StateNotifier controller managing Speaker Verification lifecycle,
/// schema-versioned event publishing over EmergencyEventBus, and Riverpod presentation state.

library;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/speech_recognition/domain/entities/speech_session.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_profile.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_state.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_request.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_error.dart';
import 'package:elly/features/emergency/speaker_verification/domain/entities/speaker_verification_events.dart';
import 'package:elly/features/emergency/speaker_verification/data/services/speaker_verification_service.dart';
import 'package:elly/features/emergency/speaker_verification/data/services/enrollment_service.dart';
import 'package:elly/features/emergency/sos/domain/services/emergency_event_bus.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';

class SpeakerVerificationController extends StateNotifier<SpeakerVerificationState> {
  SpeakerVerificationController(
    this._ref, {
    required SpeakerVerificationService service,
    required EnrollmentService enrollmentService,
  })  : _service = service,
        _enrollmentService = enrollmentService,
        super(const SpeakerVerificationState()) {
    _initEventBusListener();
    _initProfiles();
  }

  final Ref _ref;
  final SpeakerVerificationService _service;
  final EnrollmentService _enrollmentService;
  StreamSubscription<PlatformEvent>? _busSubscription;

  void _initProfiles() async {
    final profiles = await _enrollmentService.enrolledProfiles;
    final primary = await _enrollmentService.primaryProfile;
    state = state.copyWith(
      enrolledProfiles: profiles,
      activeProfile: primary,
    );
  }

  void _initEventBusListener() {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      _busSubscription = bus.events.listen((event) {
        if (event.eventName == 'SpeechRecognized' || event.eventName == 'SpeechEnded') {
          _handleAudioEvent(event);
        }
      });
    } catch (e) {
      appLogger.warning('SpeakerVerificationController: Could not subscribe to EmergencyEventBus: $e');
    }
  }

  Future<void> _handleAudioEvent(PlatformEvent event) async {
    final payload = event.payload;
    final sessionId = payload['sessionId'] as String? ?? 'sess_spk_${DateTime.now().millisecondsSinceEpoch}';

    // Build verification request
    final pcmBytes = payload['pcmData'] as Uint8List? ?? Uint8List(16000 * 2);
    final audioBuffer = AudioBuffer(pcmData: pcmBytes);

    final request = SpeakerVerificationRequest(
      sessionId: sessionId,
      audioBuffer: audioBuffer,
      timestamp: DateTime.now(),
    );

    await verifySpeaker(request);
  }

  Future<void> verifySpeaker(SpeakerVerificationRequest request) async {
    final timestamp = DateTime.now();
    final primaryProfile = await _enrollmentService.primaryProfile;
    final enrolled = await _enrollmentService.enrolledProfiles;

    state = state.copyWith(
      status: SpeakerVerificationStatus.verifying,
      activeSessionId: request.sessionId,
      activeProfile: primaryProfile,
      clearError: true,
    );

    // 1. Emit SpeakerVerificationStartedPlatformEvent
    final startEvent = SpeakerVerificationStartedPlatformEvent(
      sessionId: request.sessionId,
      timestamp: timestamp,
    );
    _publishEvent(startEvent);

    try {
      // 2. Process Verification
      final result = await _service.processRequest(request);

      // 3. Emit SpeakerVerificationCompletedPlatformEvent
      final compEvent = SpeakerVerificationCompletedPlatformEvent(
        sessionId: request.sessionId,
        processingMethod: result.processingMethod,
        embeddingVersion: result.embeddingVersion,
        processingTimeMs: result.processingTimeMs,
        timestamp: DateTime.now(),
      );
      _publishEvent(compEvent);

      // 4. Emit SpeakerVerifiedPlatformEvent (v1)
      final verEvent = SpeakerVerifiedPlatformEvent(
        sessionId: request.sessionId,
        match: result.match,
        confidence: result.confidence,
        profileId: result.profileId,
        processingMethod: result.processingMethod,
        embeddingVersion: result.embeddingVersion,
        timestamp: DateTime.now(),
      );
      _publishEvent(verEvent);

      // 5. Update State
      state = state.copyWith(
        status: SpeakerVerificationStatus.completed,
        lastResult: result,
        enrolledProfiles: enrolled,
      );

      appLogger.info('SpeakerVerificationController: 👤 Speaker Verification: Match=${result.match} (${(result.confidence * 100).toStringAsFixed(1)}%, Profile: ${result.profileId}, ${result.processingTimeMs}ms)');
    } on SpeakerVerificationError catch (e) {
      _handleError(e.category, e.message);
    } catch (e) {
      _handleError(SpeakerVerificationErrorCategory.verificationFailure, e.toString());
    }
  }

  void _handleError(SpeakerVerificationErrorCategory category, String message) {
    state = state.copyWith(
      status: SpeakerVerificationStatus.failed,
      errorCategory: category,
      errorMessage: message,
    );

    appLogger.error('SpeakerVerificationController: Verification Error [${category.name}]: $message');
  }

  void _publishEvent(PlatformEvent event) {
    try {
      final bus = _ref.read(emergencyEventBusProvider);
      bus.publish(event.eventName, event.payload);
    } catch (e) {
      appLogger.warning('SpeakerVerificationController: Could not publish Speaker event to EmergencyEventBus: $e');
    }
  }

  Future<void> enrollProfile(SpeakerProfile profile) async {
    await _enrollmentService.saveDirectProfile(profile);
    final profiles = await _enrollmentService.enrolledProfiles;
    state = state.copyWith(
      activeProfile: profile,
      enrolledProfiles: profiles,
    );
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
