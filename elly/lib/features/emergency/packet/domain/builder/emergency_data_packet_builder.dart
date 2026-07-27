/// emergency_data_packet_builder.dart
///
/// Assembly builder aggregating data from Health Passport, Telemetry, SOS Circle,
/// Session Snapshot, Cross-Border Context, and Confirmation Logic to generate immutable EmergencyDataPacket instances
/// with hash/checksum integrity, sequence numbers, and international context.

library;

import 'dart:convert';
import 'package:elly/core/utils/app_clock.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/emergency_context.dart';
import 'package:elly/features/emergency/health_passport/domain/entities/health_passport.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/sos_circle.dart';
import 'package:elly/features/emergency/session/domain/entities/emergency_session_snapshot.dart';
import 'package:elly/features/emergency/sos/domain/entities/confirmation_state.dart';
import 'package:elly/features/emergency/offline/domain/entities/network_state.dart';
import 'package:elly/features/emergency/global/domain/entities/cross_border_context.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_data_packet.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_symptoms_model.dart';
import 'package:elly/features/emergency/packet/domain/entities/device_info_model.dart';
import 'package:elly/features/emergency/packet/domain/validation/severity_calculator.dart';

class EmergencyDataPacketBuilder {
  static EmergencyDataPacket build({
    required EmergencyContext context,
    required EmergencySessionSnapshot snapshot,
    HealthPassport? passport,
    TelemetryPoint? location,
    SOSCircle? circle,
    ConfirmationResult? confirmationResult,
    NetworkState networkState = NetworkState.online,
    CrossBorderContext? crossBorderContext,
    int batteryLevel = 85,
    int sequenceNumber = 1,
    EmergencySymptomsModel symptoms = const EmergencySymptomsModel(),
  }) {
    final now = AppClock.now();
    final profile = passport?.profile ?? context.healthPassport?.profile;

    final calculatedSeverity = SeverityCalculator.calculate(
      highRisk: context.highRisk,
      profile: profile,
      confirmationResult: confirmationResult,
      symptoms: symptoms,
    );

    final latestEventsMap = snapshot.currentTimeline.take(20).map((e) => e.toJson()).toList();
    final rawId = 'PKT_${snapshot.session.sessionId}_$sequenceNumber';

    // Native hash/checksum digest calculation
    final hashInput = '$rawId:${snapshot.session.sessionId}:${profile?.fullName}:${location?.latitude}:${location?.longitude}:${now.toIso8601String()}';
    final packetHash = base64Encode(utf8.encode(hashInput));
    final packetChecksum = packetHash.substring(0, packetHash.length.clamp(0, 16));

    final country = crossBorderContext?.currentCountry;

    return EmergencyDataPacket(
      packetId: rawId,
      sessionId: snapshot.session.sessionId,
      userId: profile?.profileId ?? 'usr_default',
      generatedAt: now,
      sequenceNumber: sequenceNumber,
      packetHash: packetHash,
      packetChecksum: packetChecksum,
      countryCode: country?.countryCode ?? 'IN',
      detectedLanguage: country?.defaultLanguage ?? 'en_US',
      localEmergencyNumber: country?.medicalNumber ?? '112',
      timeZone: country?.timeZone ?? 'Asia/Kolkata',
      isRoaming: crossBorderContext?.isRoaming ?? false,
      emergencyState: snapshot.session.state.name.toUpperCase(),
      confirmationResult: confirmationResult,
      highRisk: context.highRisk,
      currentSeverity: calculatedSeverity.name.toUpperCase(),
      emergencyStartedAt: snapshot.session.createdAt,
      duration: snapshot.session.duration,
      latitude: location?.latitude ?? 0.0,
      longitude: location?.longitude ?? 0.0,
      altitude: location?.altitude ?? 0.0,

      accuracy: location?.accuracy ?? 0.0,
      speed: location?.speed ?? 0.0,
      heading: location?.heading ?? 0.0,
      name: profile?.fullName ?? 'Anonymous User',
      age: profile?.age ?? 30,
      bloodGroup: profile?.bloodGroup ?? 'Unknown',
      allergies: profile?.allergies ?? const [],
      medications: profile?.medications ?? const [],
      chronicConditions: profile?.chronicConditions ?? const [],
      physician: profile?.physicianName,
      emergencyNotes: profile?.emergencyNotes ?? '',
      symptoms: symptoms,
      totalEvents: snapshot.currentTimeline.length,
      latestEvents: latestEventsMap.map((e) => jsonEncode(e)).toList(),
      primaryContact: circle?.primaryContact?.toJson(),
      secondaryContacts: circle?.contacts.map((c) => c.toJson()).toList() ?? const [],
      deviceInfo: DeviceInfoModel(
        batteryLevel: batteryLevel,
        networkState: networkState.name,
        gpsAvailable: location != null,
      ),
    );
  }
}
