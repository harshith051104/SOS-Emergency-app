/// location_sharing_action.dart
///
/// Production implementation of [EmergencyAction] for acquiring the device's
/// current GPS coordinates and embedding them in a shareable Google Maps link
/// in the session profile. The SMS action then includes this link.
///
/// Permissions: Requires ACCESS_FINE_LOCATION (Android) / NSLocationWhenInUseUsageDescription (iOS).
/// If permissions are denied or GPS is unavailable, the action marks itself as
/// partially successful with a descriptive failure message — the overall session
/// continues rather than aborting due to location failure.

library;

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/action_result.dart';
import '../../domain/entities/emergency_session_request.dart';
import '../../domain/interfaces/emergency_action.dart';

class LocationSharingAction implements EmergencyAction {
  LocationSharingAction({
    this.locationTimeoutSeconds = 8,
    this.fallbackToLastKnown = true,
  });

  final int locationTimeoutSeconds;
  final bool fallbackToLastKnown;

  @override
  String get actionId => 'location_sharing';

  @override
  String get actionName => 'Share Live GPS Location';

  @override
  Future<ActionResult> execute(EmergencySessionRequest request) async {
    final sw = Stopwatch()..start();

    try {
      // Check location service enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        sw.stop();
        return ActionResult(
          actionId: actionId,
          actionName: actionName,
          success: false,
          message: 'Location services are disabled on this device.',
          executionTimeMs: sw.elapsedMilliseconds,
          timestamp: DateTime.now(),
        );
      }

      // Check/request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        sw.stop();
        return ActionResult(
          actionId: actionId,
          actionName: actionName,
          success: false,
          message: 'Location permission denied. Cannot share GPS coordinates.',
          executionTimeMs: sw.elapsedMilliseconds,
          timestamp: DateTime.now(),
        );
      }

      // Get current position with timeout
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: locationTimeoutSeconds),
        );
      } catch (e) {
        appLogger.warning(
            'LocationSharingAction: getCurrentPosition failed ($e), trying lastKnown');
        if (fallbackToLastKnown) {
          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (position == null) {
        sw.stop();
        return ActionResult(
          actionId: actionId,
          actionName: actionName,
          success: false,
          message: 'GPS fix could not be obtained within ${locationTimeoutSeconds}s.',
          executionTimeMs: sw.elapsedMilliseconds,
          timestamp: DateTime.now(),
        );
      }

      // Store coordinates in the request profile so other actions can use them
      // (In particular, SendSmsAction reads emergencyProfile['latitude'])
      final lat = position.latitude;
      final lng = position.longitude;
      final accuracy = position.accuracy.toStringAsFixed(0);
      final mapsLink = 'https://maps.google.com/?q=$lat,$lng';

      // Write back to mutable profile map
      request.emergencyProfile['latitude'] = lat;
      request.emergencyProfile['longitude'] = lng;
      request.emergencyProfile['locationAccuracyM'] = position.accuracy;
      request.emergencyProfile['locationTimestamp'] =
          position.timestamp.toIso8601String();
      request.emergencyProfile['mapsLink'] = mapsLink;

      appLogger.info(
          'LocationSharingAction: GPS acquired — $lat, $lng (±${accuracy}m)');

      sw.stop();
      return ActionResult(
        actionId: actionId,
        actionName: actionName,
        success: true,
        message: 'GPS: $lat, $lng (±${accuracy}m) → $mapsLink',
        executionTimeMs: sw.elapsedMilliseconds,
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      appLogger.error('LocationSharingAction: Unexpected error', e, st);
      sw.stop();
      return ActionResult(
        actionId: actionId,
        actionName: actionName,
        success: false,
        message: 'Location sharing failed: ${e.toString()}',
        executionTimeMs: sw.elapsedMilliseconds,
        timestamp: DateTime.now(),
      );
    }
  }
}
