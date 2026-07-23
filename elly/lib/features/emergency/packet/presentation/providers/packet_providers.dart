/// packet_providers.dart
///
/// Riverpod dependency injection wiring for the Emergency Data Packet feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../responders/presentation/providers/responder_providers.dart';
import '../../../sos/domain/entities/emergency_session.dart';
import '../../../sos/presentation/providers/emergency_providers.dart';
import '../../data/repositories/packet_repository_impl.dart';
import '../../data/services/contributors/device_contributor.dart';
import '../../data/services/contributors/emergency_contributor.dart';
import '../../data/services/contributors/location_contributor.dart';
import '../../data/services/contributors/medical_contributor.dart';
import '../../data/services/contributors/responder_contributor.dart';
import '../../data/services/contributors/timeline_contributor.dart';
import '../../data/services/device_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/packet_builder.dart';
import '../../data/services/packet_contributor.dart';
import '../../data/services/packet_serializer.dart';
import '../../data/services/packet_storage.dart';
import '../../data/services/timeline_service.dart';
import '../../domain/entities/responder_section.dart';
import '../../domain/repositories/packet_repository.dart';
import '../../domain/usecases/generate_packet_usecase.dart';
import '../../domain/usecases/get_medical_profile_usecase.dart';
import '../../domain/usecases/save_medical_profile_usecase.dart';
import 'package:elly/features/emergency/packet/data/services/medical_profile_service.dart';
import '../controllers/packet_controller.dart';

final medicalProfileServiceProvider = Provider<MedicalProfileService>((ref) {
  return MedicalProfileService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

final timelineServiceProvider = Provider<TimelineService>((ref) {
  return TimelineService();
});

final packetStorageProvider = Provider<EmergencyPacketStorage>((ref) {
  return EmergencyPacketStorage();
});

final packetSerializerProvider = Provider<EmergencyPacketSerializer>((ref) {
  return const EmergencyPacketSerializer();
});

final packetContributorsProvider = Provider<List<PacketContributor>>((ref) {
  final timelineService = ref.watch(timelineServiceProvider);
  final locationService = ref.watch(locationServiceProvider);
  final deviceService = ref.watch(deviceServiceProvider);

  // Read responders use case for mapping contacts
  final getResponders = ref.watch(getRespondersUseCaseProvider);

  return [
    EmergencyContributor(timelineService),
    DeviceContributor(
      deviceService: deviceService,
      timelineService: timelineService,
    ),
    LocationContributor(
      locationService: locationService,
      timelineService: timelineService,
    ),
    MedicalContributor(
      fetchMedicalProfile: () => ref.read(medicalProfileServiceProvider).getMedicalProfile(),
      timelineService: timelineService,
    ),
    ResponderContributor(
      fetchResponders: () async {
        final activeSession = ref.read(emergencyControllerProvider).activeSession;
        final list = await getResponders();

        return list.map((r) {
          var state = ResponderNotificationStatus.pending;
          var isAck = false;
          DateTime? ackTime;

          if (activeSession != null) {
            // Find corresponding state in SOS controller session
            final matched = activeSession.responderStatuses.firstWhere(
              (s) => s.responder.id == r.id,
              orElse: () => ResponderSessionStatus(
                responder: r,
                state: ResponderSessionState.pending,
              ),
            );

            switch (matched.state) {
              case ResponderSessionState.pending:
                state = ResponderNotificationStatus.pending;
                break;
              case ResponderSessionState.notified:
                state = ResponderNotificationStatus.notified;
                break;
              case ResponderSessionState.accepted:
                state = ResponderNotificationStatus.accepted;
                isAck = true;
                ackTime = DateTime.now().subtract(const Duration(seconds: 1));
                break;
              case ResponderSessionState.timedOut:
                state = ResponderNotificationStatus.timedOut;
                break;
            }
          }

          return EmergencyResponder(
            id: r.id,
            name: r.name,
            relationship: r.type.displayName,
            phone: r.phoneNumber ?? '',
            notificationStatus: state,
            isAcknowledged: isAck,
            acknowledgedTime: ackTime,
          );
        }).toList();
      },
      timelineService: timelineService,
    ),
    TimelineContributor(timelineService),
  ];
});

final packetBuilderProvider = Provider<EmergencyPacketBuilder>((ref) {
  return EmergencyPacketBuilder(ref.watch(packetContributorsProvider));
});

final packetRepositoryProvider = Provider<PacketRepository>((ref) {
  return PacketRepositoryImpl(
    builder: ref.watch(packetBuilderProvider),
    serializer: ref.watch(packetSerializerProvider),
    storage: ref.watch(packetStorageProvider),
    medicalProfileService: ref.watch(medicalProfileServiceProvider),
  );
});

final generatePacketUseCaseProvider = Provider<GeneratePacketUseCase>((ref) {
  return GeneratePacketUseCase(ref.watch(packetRepositoryProvider));
});

final getMedicalProfileUseCaseProvider = Provider<GetMedicalProfileUseCase>((ref) {
  return GetMedicalProfileUseCase(ref.watch(packetRepositoryProvider));
});

final saveMedicalProfileUseCaseProvider = Provider<SaveMedicalProfileUseCase>((ref) {
  return SaveMedicalProfileUseCase(ref.watch(packetRepositoryProvider));
});

/// Exposes the packet controller.
final packetControllerProvider =
    StateNotifierProvider.family<EmergencyPacketController, EmergencyPacketState, String>((ref, sessionId) {
  return EmergencyPacketController(
    sessionId: sessionId,
    generatePacketUseCase: ref.watch(generatePacketUseCaseProvider),
    timelineService: ref.watch(timelineServiceProvider),
  );
});
