/// packet_providers.dart
///
/// Riverpod dependency injection definitions exposing reactive EmergencyDataPacket assembly,
/// packet validation, location service, timeline service, packetControllerProvider, and DI wiring across platform engines.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/health_passport/presentation/providers/health_passport_providers.dart';
import 'package:elly/features/emergency/telemetry/presentation/providers/telemetry_providers.dart';
import 'package:elly/features/emergency/sos_circle/presentation/providers/sos_circle_providers.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/sos/presentation/controllers/emergency_session_controller.dart';
import 'package:elly/features/emergency/global/presentation/providers/global_providers.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_data_packet.dart';

import 'package:elly/features/emergency/packet/domain/builder/emergency_data_packet_builder.dart' as new_builder;
import 'package:elly/features/emergency/packet/domain/validation/emergency_data_packet_validator.dart';
import 'package:elly/features/emergency/packet/data/services/location_service.dart';
import 'package:elly/features/emergency/packet/data/services/timeline_service.dart';
import 'package:elly/features/emergency/packet/presentation/controllers/packet_controller.dart';
import 'package:elly/features/emergency/packet/domain/usecases/generate_packet_usecase.dart';
import 'package:elly/features/emergency/packet/domain/repositories/packet_repository.dart';
import 'package:elly/features/emergency/packet/data/repositories/packet_repository_impl.dart';
import 'package:elly/features/emergency/packet/data/services/packet_builder.dart';
import 'package:elly/features/emergency/packet/data/services/packet_serializer.dart';
import 'package:elly/features/emergency/packet/data/services/packet_storage.dart';
import 'package:elly/features/emergency/packet/data/services/medical_profile_service.dart';
import 'package:elly/features/emergency/packet/data/services/device_service.dart';
import 'package:elly/features/emergency/packet/data/services/contributors/emergency_contributor.dart';
import 'package:elly/features/emergency/packet/data/services/contributors/location_contributor.dart';
import 'package:elly/features/emergency/packet/data/services/contributors/device_contributor.dart';
import 'package:elly/features/emergency/packet/data/services/contributors/medical_contributor.dart';
import 'package:elly/features/emergency/packet/data/services/contributors/responder_contributor.dart';
import 'package:elly/features/emergency/packet/data/services/contributors/timeline_contributor.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

final timelineServiceProvider = Provider<TimelineService>((ref) {
  return TimelineService();
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

final packetStorageProvider = Provider<EmergencyPacketStorage>((ref) => EmergencyPacketStorage());
final packetSerializerProvider = Provider<EmergencyPacketSerializer>((ref) => const EmergencyPacketSerializer());
final medicalProfileServiceProvider = Provider<MedicalProfileService>((ref) => MedicalProfileService());


final legacyPacketBuilderProvider = Provider<EmergencyPacketBuilder>((ref) {
  final timeline = ref.watch(timelineServiceProvider);
  final location = ref.watch(locationServiceProvider);
  final device = ref.watch(deviceServiceProvider);

  return EmergencyPacketBuilder([
    EmergencyContributor(timeline),
    LocationContributor(locationService: location, timelineService: timeline),
    DeviceContributor(deviceService: device, timelineService: timeline),
    MedicalContributor(
      fetchMedicalProfile: () async {
        final profileService = ref.read(medicalProfileServiceProvider);
        return profileService.getMedicalProfile();
      },
      timelineService: timeline,
    ),
    ResponderContributor(
      fetchResponders: () async => [],
      timelineService: timeline,
    ),
    TimelineContributor(timeline),
  ]);
});

final packetRepositoryProvider = Provider<PacketRepository>((ref) {
  return PacketRepositoryImpl(
    builder: ref.watch(legacyPacketBuilderProvider),
    serializer: ref.watch(packetSerializerProvider),
    storage: ref.watch(packetStorageProvider),
    medicalProfileService: ref.watch(medicalProfileServiceProvider),
  );
});

final generatePacketUseCaseProvider = Provider<GeneratePacketUseCase>((ref) {
  return GeneratePacketUseCase(ref.watch(packetRepositoryProvider));
});

final packetControllerProvider =
    StateNotifierProvider.family<EmergencyPacketController, EmergencyPacketState, String>(
        (ref, sessionId) {
  return EmergencyPacketController(
    sessionId: sessionId,
    generatePacketUseCase: ref.watch(generatePacketUseCaseProvider),
    timelineService: ref.watch(timelineServiceProvider),
  );
});

final emergencyDataPacketProvider = Provider<EmergencyDataPacket>((ref) {

  final context = ref.watch(emergencyContextProvider);
  final snapshot = ref.watch(sessionSnapshotProvider);
  final location = ref.watch(latestTelemetryPointProvider);
  final circle = ref.watch(sosCircleStateProvider);
  final netState = ref.watch(networkStateProvider);
  final sosSessionState = ref.watch(emergencySessionControllerProvider);
  final globalCtx = ref.watch(crossBorderControllerProvider);

  final packet = new_builder.EmergencyDataPacketBuilder.build(
    context: context,
    snapshot: snapshot,
    location: location,
    circle: circle,
    confirmationResult: sosSessionState.lastConfirmationResult,
    networkState: netState,
    crossBorderContext: globalCtx,
  );


  final valReport = EmergencyDataPacketValidator.validate(packet);
  if (!valReport.isValid) {
    // Validated domain packet warnings
  }

  return packet;
});
