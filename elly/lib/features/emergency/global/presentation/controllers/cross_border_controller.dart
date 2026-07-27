/// cross_border_controller.dart
///
/// Master presentation controller managing global country resolution, roaming detection,
/// emergency directory lookup, timeline event logging, and EventBus publishing.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/global/domain/entities/cross_border_context.dart';
import 'package:elly/features/emergency/global/domain/entities/emergency_service_directory.dart';

import 'package:elly/features/emergency/global/domain/entities/country_detection_result.dart';
import 'package:elly/features/emergency/global/domain/services/country_resolver.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_timeline_event.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/sos/domain/entities/emergency_platform_events.dart';

class CrossBorderController extends StateNotifier<CrossBorderContext> {
  CrossBorderController(this._ref)
      : super(CrossBorderContext(
          currentCountry: EmergencyServiceDirectory.getProfile('IN'),
          homeCountry: EmergencyServiceDirectory.getProfile('IN'),
        ));

  final Ref _ref;

  void evaluateCountry({
    dynamic location,
    String? locale,
    String? manualOverrideCode,
  }) {
    final result = CountryResolver.resolve(
      location: location,
      locale: locale,
      manualOverrideCode: manualOverrideCode,
    );

    final resolvedProfile = CountryResolver.getProfileForResult(result);
    final previousCountryCode = state.currentCountry.countryCode;
    final wasRoaming = state.isRoaming;

    final isDifferent = previousCountryCode != resolvedProfile.countryCode;
    final isRoaming = resolvedProfile.countryCode != state.homeCountry.countryCode;

    final now = AppClock.now();

    state = state.copyWith(
      currentCountry: resolvedProfile,
      hasBorderCrossed: isDifferent,
      isRoaming: isRoaming,
      lastDetectedAt: now,
      lastDetectionResult: result,
    );

    appLogger.info('CrossBorderController: Resolved country ${resolvedProfile.countryCode} (${resolvedProfile.countryName}) via ${result.source.name}');

    // Audit Manual Override
    if (result.source == DetectionSource.manualOverride) {
      _recordTimeline(
        title: 'Manual Override Audit',
        description: 'User manually overrode country code to ${resolvedProfile.countryCode}.',
        severity: EventSeverity.warning,
      );
    }

    // Publish CountryDetected Event
    _ref.read(emergencyEventBusProvider).publish(
      'CountryDetected',
      CountryDetectedPlatformEvent(
        eventId: 'evt_country_det_${now.millisecondsSinceEpoch}',
        timestamp: now,
        countryCode: resolvedProfile.countryCode,
        detectionSource: result.source.name,
      ).toJson(),
    );

    if (isDifferent) {
      _ref.read(emergencyEventBusProvider).publish(
        'CountryChanged',
        CountryChangedPlatformEvent(
          eventId: 'evt_country_chg_${now.millisecondsSinceEpoch}',
          timestamp: now,
          oldCountryCode: previousCountryCode,
          newCountryCode: resolvedProfile.countryCode,
        ).toJson(),
      );

      _recordTimeline(
        title: 'Country Changed',
        description: 'Border crossed: Switched response directory from $previousCountryCode ➔ ${resolvedProfile.countryCode}.',
        severity: EventSeverity.warning,
      );

      _recordTimeline(
        title: 'Emergency Directory Switched',
        description: 'Switched Emergency Directory v${resolvedProfile.directoryVersion} for ${resolvedProfile.countryName}.',
        severity: EventSeverity.info,
      );

      _recordTimeline(
        title: 'Emergency Number Updated',
        description: 'Updated dispatch lines: Medical (${resolvedProfile.medicalNumber}), Police (${resolvedProfile.policeNumber}), Fire (${resolvedProfile.fireNumber}).',
        severity: EventSeverity.info,
      );
    } else {
      _recordTimeline(
        title: 'Country Detected',
        description: 'Active country verified: ${resolvedProfile.countryName} (${resolvedProfile.countryCode}).',
        severity: EventSeverity.info,
      );
    }

    if (isRoaming && !wasRoaming) {
      _ref.read(emergencyEventBusProvider).publish(
        'RoamingDetected',
        RoamingDetectedPlatformEvent(
          eventId: 'evt_roam_${now.millisecondsSinceEpoch}',
          timestamp: now,
          countryCode: resolvedProfile.countryCode,
        ).toJson(),
      );

      _recordTimeline(
        title: 'Entered Roaming',
        description: 'Device entered international roaming in ${resolvedProfile.countryName}.',
        severity: EventSeverity.warning,
      );
    } else if (!isRoaming && wasRoaming) {
      _recordTimeline(
        title: 'Exited Roaming',
        description: 'Device returned to home network (${state.homeCountry.countryName}).',
        severity: EventSeverity.info,
      );
    }
  }

  void setManualOverride(String countryCode) {
    evaluateCountry(manualOverrideCode: countryCode);
  }

  void _recordTimeline({
    required String title,
    required String description,
    required EventSeverity severity,
  }) {
    try {
      final repo = _ref.read(emergencySessionRepositoryProvider);
      repo.recordTimelineEvent(EmergencyTimelineEvent(
        id: 'evt_global_${AppClock.now().millisecondsSinceEpoch}',
        timestamp: AppClock.now(),
        category: EventCategory.system,
        severity: severity,
        title: title,
        description: description,
        sourceEngine: 'Cross-Border Engine',
      ));
    } catch (e) {
      appLogger.warning('CrossBorderController: Could not log timeline event: $e');
    }
  }
}
