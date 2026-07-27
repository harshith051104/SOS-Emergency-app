/// packet_builder_test.dart
///
/// Unit tests for the EmergencyPacketBuilder pipeline.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:elly/features/emergency/packet/data/services/packet_builder.dart';
import 'package:elly/features/emergency/packet/data/services/packet_contributor.dart';
import 'package:elly/features/emergency/packet/domain/entities/location_section.dart';

class MockLocationContributor implements PacketContributor {
  @override
  Future<void> contribute(EmergencyPacketBuilderContext context) async {
    context.location = LocationSection(
      latitude: 12.3456,
      longitude: 78.9012,
      address: 'Test Location',
      accuracy: '5.0m',
      timestamp: DateTime.now(),
      permissionStatus: 'whileInUse',
      isGpsEnabled: true,
      isMockLocation: true,
    );
  }
}

void main() {
  group('EmergencyPacketBuilder Tests', () {
    test('build compiles data through contributors successfully', () async {
      final builder = EmergencyPacketBuilder([
        MockLocationContributor(),
      ]);

      final packet = await builder.build(
        id: 'EP-TEST-123',
        sessionId: 'session_abc',
        type: 'test_sos',
      );

      expect(packet.id, 'EP-TEST-123');
      expect(packet.sessionId, 'session_abc');
      expect(packet.type, 'test_sos');
      expect(packet.location.latitude, 12.3456);
      expect(packet.location.address, 'Test Location');
      expect(packet.metadata.version, 1);
      expect(packet.metadata.generatedBy, 'ELLY_SOS_V1');
      expect(packet.metadata.checksum.length, 16); // Hex-encoded FNV-1a hash
      expect(packet.metadata.packetSize.contains('KB'), true);
    });

    test('build handles fallback values when contributors are empty', () async {
      final builder = EmergencyPacketBuilder([]);

      final packet = await builder.build(
        id: 'EP-FALLBACK',
        sessionId: 'session_xyz',
        type: 'manual',
      );

      expect(packet.location.address, 'Location Unavailable');
      expect(packet.device.deviceName, 'Generic Device');
      expect(packet.medical.medicalInfo.bloodGroup, 'Unknown');
      expect(packet.responders.responders.isEmpty, true);
    });
    group('LocationSectionFallback Tests', () {
      test('create creates robust fallback LocationSection', () {
        final fallback = LocationSectionFallback.create();
        expect(fallback.latitude, isNull);
        expect(fallback.address, 'Location Unavailable');
      });
    });
  });
}
