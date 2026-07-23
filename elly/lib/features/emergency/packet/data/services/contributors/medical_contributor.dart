/// medical_contributor.dart
///
/// Contributor that loads the local medical profile details and appends them to the packet.

library;

import 'package:elly/features/emergency/packet/domain/entities/medical_section.dart';
import 'package:elly/features/emergency/packet/data/services/packet_contributor.dart';
import 'package:elly/features/emergency/packet/data/services/timeline_service.dart';

class MedicalContributor implements PacketContributor {
  const MedicalContributor({
    required Future<MedicalSection> Function() fetchMedicalProfile,
    required TimelineService timelineService,
  })  : _fetchMedicalProfile = fetchMedicalProfile,
        _timelineService = timelineService;

  final Future<MedicalSection> Function() _fetchMedicalProfile;
  final TimelineService _timelineService;

  @override
  Future<void> contribute(EmergencyPacketBuilderContext context) async {
    final profile = await _fetchMedicalProfile();
    context.medical = profile;

    _timelineService.append(
      title: 'Medical Profile Loaded',
      description: 'Blood Group: ${profile.medicalInfo.bloodGroup}, Allergies: ${profile.medicalInfo.allergies.length} logged.',
    );
  }
}
