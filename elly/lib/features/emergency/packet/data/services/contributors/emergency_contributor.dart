/// emergency_contributor.dart
///
/// Contributor that registers the emergency start event in the timeline log.

library;

import '../packet_contributor.dart';
import '../timeline_service.dart';

class EmergencyContributor implements PacketContributor {
  const EmergencyContributor(this._timelineService);

  final TimelineService _timelineService;

  @override
  Future<void> contribute(EmergencyPacketBuilderContext context) async {
    _timelineService.append(
      title: 'Emergency Started',
      description: 'SOS trigger registered (Type: ${context.type.toUpperCase()}).',
    );
  }
}
