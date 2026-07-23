/// packet_controller_test.dart
///
/// Unit and provider tests for the EmergencyPacketController.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:elly/features/emergency/packet/data/services/timeline_service.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_packet.dart';
import 'package:elly/features/emergency/packet/domain/usecases/generate_packet_usecase.dart';
import 'package:elly/features/emergency/packet/presentation/controllers/packet_controller.dart';
import 'package:elly/features/emergency/packet/domain/entities/location_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/device_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/medical_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/responder_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/timeline_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/packet_metadata.dart';

class MockGeneratePacketUseCase extends Mock implements GeneratePacketUseCase {}

void main() {
  late MockGeneratePacketUseCase mockUseCase;
  late TimelineService timelineService;

  final dummyPacket = EmergencyPacket(
    id: 'EP-DUMMY',
    sessionId: 'session_123',
    version: 1,
    type: 'Manual SOS',
    status: 'active',
    startedAt: DateTime.now(),
    currentTime: DateTime.now(),
    duration: Duration.zero,
    metadata: PacketMetadata(
      created: DateTime.now(),
      updated: DateTime.now(),
      version: 1,
      generatedBy: 'TEST',
      packetSize: '1.2 KB',
      checksum: 'A1B2C3D4E5F67890',
    ),
    location: LocationSection(
      latitude: 0,
      longitude: 0,
      address: 'Test Address',
      accuracy: '10m',
      timestamp: DateTime.now(),
      permissionStatus: 'whileInUse',
      isGpsEnabled: true,
      isMockLocation: true,
    ),
    device: const DeviceSection(
      batteryPercent: 88,
      isCharging: false,
      connectionType: 'wifi',
      isInternetAvailable: true,
      platform: 'Android',
      deviceName: 'Emulator',
      osVersion: 'Android 13',
      isScreenLocked: false,
      isBatterySaverEnabled: false,
      isLowPowerMode: false,
      timeZone: 'GMT',
      locale: 'en_US',
    ),
    medical: const MedicalSection(
      medicalInfo: MedicalInformation(
        bloodGroup: 'A+',
        allergies: [],
        medicalConditions: [],
        currentMedications: [],
      ),
      emergencyInfo: EmergencyInformation(
        emergencyNotes: 'None',
        doctorName: 'None',
        doctorPhone: 'None',
        insuranceProvider: 'None',
        insurancePolicyNumber: 'None',
        preferredHospital: 'None',
      ),
    ),
    responders: const ResponderSection(responders: []),
    timeline: const TimelineSection(events: []),
  );

  setUp(() {
    mockUseCase = MockGeneratePacketUseCase();
    timelineService = TimelineService();

    when(() => mockUseCase.call(
          id: any(named: 'id'),
          sessionId: any(named: 'sessionId'),
          type: any(named: 'type'),
        )).thenAnswer((_) async => dummyPacket);
  });

  group('EmergencyPacketController Tests', () {
    test('initializes and executes building pipeline successfully', () async {
      final controller = EmergencyPacketController(
        sessionId: 'session_123',
        generatePacketUseCase: mockUseCase,
        timelineService: timelineService,
      );

      // Verify it enters building status
      expect(controller.state.status, PacketStateStatus.building);

      // Wait for the simulated pipeline delays to complete
      await Future<void>.delayed(const Duration(milliseconds: 2000));

      expect(controller.state.status, PacketStateStatus.ready);
      expect(controller.state.packet, dummyPacket);
      expect(controller.state.buildingProgress, 6);
    });

    test('transitions to failed state when generatePacket fails', () async {
      when(() => mockUseCase.call(
            id: any(named: 'id'),
            sessionId: any(named: 'sessionId'),
            type: any(named: 'type'),
          )).thenThrow(Exception('Simulated compilation failure'));

      final controller = EmergencyPacketController(
        sessionId: 'session_123',
        generatePacketUseCase: mockUseCase,
        timelineService: timelineService,
      );

      // Wait for delays
      await Future<void>.delayed(const Duration(milliseconds: 2000));

      expect(controller.state.status, PacketStateStatus.failed);
      expect(controller.state.errorMessage, contains('Simulated compilation failure'));
    });
  });
}
