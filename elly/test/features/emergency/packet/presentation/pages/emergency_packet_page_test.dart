/// emergency_packet_page_test.dart
///
/// Widget tests for the premium M3 EmergencyPacketPage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/packet/domain/entities/emergency_packet.dart';
import 'package:elly/features/emergency/packet/domain/entities/device_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/location_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/medical_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/responder_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/timeline_section.dart';
import 'package:elly/features/emergency/packet/domain/entities/packet_metadata.dart';
import 'package:elly/features/emergency/packet/presentation/pages/emergency_packet_page.dart';
import 'package:elly/features/emergency/packet/presentation/controllers/packet_controller.dart';
import 'package:elly/features/emergency/packet/presentation/providers/packet_providers.dart';
import 'package:elly/features/emergency/packet/domain/usecases/generate_packet_usecase.dart';
import 'package:elly/features/emergency/packet/data/services/timeline_service.dart';

class FakePacketController extends EmergencyPacketController {
  FakePacketController(
    EmergencyPacketState state,
  ) : super(
          sessionId: 'session_123',
          generatePacketUseCase: _DummyUseCase(),
          timelineService: _DummyTimelineService(),
          autoStart: false,
        ) {
    this.state = state;
  }
}

class _DummyUseCase implements GeneratePacketUseCase {
  @override
  Future<EmergencyPacket> call({
    required String id,
    required String sessionId,
    required String type,
  }) async => throw UnimplementedError();
}

class _DummyTimelineService implements TimelineService {
  @override
  void append({required String title, required String description}) {}
  @override
  void clear() {}
  @override
  List<TimelineEvent> get events => [];
  @override
  void remove(String id) {}
}

void main() {
  final dummyPacket = EmergencyPacket(
    id: 'EP-12345',
    sessionId: 'session_123',
    version: 1,
    type: 'Manual SOS',
    status: 'active',
    startedAt: DateTime.now(),
    currentTime: DateTime.now(),
    duration: const Duration(seconds: 12),
    metadata: PacketMetadata(
      created: DateTime.now(),
      updated: DateTime.now(),
      version: 1,
      generatedBy: 'TEST',
      packetSize: '2.5 KB',
      checksum: 'A1B2C3D4E5F67890',
    ),
    location: LocationSection(
      latitude: 17.3850,
      longitude: 78.4866,
      address: 'Jubilee Hills, Hyderabad, India',
      accuracy: '4.2m',
      timestamp: DateTime.now(),
      permissionStatus: 'whileInUse',
      isGpsEnabled: true,
      isMockLocation: false,
    ),
    device: const DeviceSection(
      batteryPercent: 95,
      isCharging: true,
      connectionType: 'wifi',
      isInternetAvailable: true,
      platform: 'Android',
      deviceName: 'Pixel 7',
      osVersion: 'Android 13',
      isScreenLocked: false,
      isBatterySaverEnabled: false,
      isLowPowerMode: false,
      timeZone: 'IST',
      locale: 'en_IN',
    ),
    medical: const MedicalSection(
      medicalInfo: MedicalInformation(
        bloodGroup: 'B+',
        allergies: ['Peanuts'],
        medicalConditions: [],
        currentMedications: [],
      ),
      emergencyInfo: EmergencyInformation(
        emergencyNotes: 'No extra details',
        doctorName: 'Dr. Srinivas',
        doctorPhone: '+91 99887 76655',
        insuranceProvider: 'None',
        insurancePolicyNumber: 'None',
        preferredHospital: 'None',
      ),
    ),
    responders: const ResponderSection(responders: []),
    timeline: const TimelineSection(events: []),
  );

  testWidgets('renders compilation checklist when state is building', (WidgetTester tester) async {
    const state = EmergencyPacketState(
      status: PacketStateStatus.building,
      buildingProgress: 3,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packetControllerProvider('session_123').overrideWith(
            (ref) => FakePacketController(state),
          ),
        ],
        child: const MaterialApp(
          home: EmergencyPacketPage(sessionId: 'session_123'),
        ),
      ),
    );

    expect(find.text('Compiling Emergency Packet'), findsOneWidget);
    expect(find.text('Collect Device Diagnostics & Sensors'), findsOneWidget);
    expect(find.text('Retrieve GPS Coordinates & Address'), findsOneWidget);
  });

  testWidgets('renders full telemetry cards when state is ready', (WidgetTester tester) async {
    // Set larger surface size so lazy ListView renders off-screen cards
    await tester.binding.setSurfaceSize(const Size(800, 1600));

    final state = EmergencyPacketState(
      status: PacketStateStatus.ready,
      packet: dummyPacket,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packetControllerProvider('session_123').overrideWith(
            (ref) => FakePacketController(state),
          ),
        ],
        child: const MaterialApp(
          home: EmergencyPacketPage(sessionId: 'session_123'),
        ),
      ),
    );

    // Verify summary details
    expect(find.textContaining('EP-12345'), findsOneWidget);
    expect(find.text('2.5 KB'), findsOneWidget);

    // Verify location card details
    expect(find.text('Jubilee Hills, Hyderabad, India'), findsOneWidget);
    expect(find.text('17.385000, 78.486600'), findsOneWidget);

    // Verify medical card details
    expect(find.text('B+'), findsOneWidget);
    expect(find.text('Peanuts'), findsOneWidget);

    // Verify hardware details
    expect(find.text('Pixel 7'), findsOneWidget);
    expect(find.text('Battery Level'), findsOneWidget);

    // Reset surface size to default
    await tester.binding.setSurfaceSize(null);
  });
}
