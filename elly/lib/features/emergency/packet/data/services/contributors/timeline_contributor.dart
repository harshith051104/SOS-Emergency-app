/// timeline_contributor.dart
///
/// Contributor that locks the timeline log state and appends the final compilation milestone.

library;

import 'package:elly/features/emergency/packet/domain/entities/timeline_section.dart';
import 'package:elly/features/emergency/packet/data/services/packet_contributor.dart';
import 'package:elly/features/emergency/packet/data/services/timeline_service.dart';

class TimelineContributor implements PacketContributor {
  const TimelineContributor(this._timelineService);

  final TimelineService _timelineService;

  @override
  Future<void> contribute(EmergencyPacketBuilderContext context) async {
    _timelineService.append(
      title: 'Packet Completed',
      description: 'All system and hardware telemetries compiled successfully.',
    );

    context.timeline = TimelineSection(events: _timelineService.events);
  }
}
