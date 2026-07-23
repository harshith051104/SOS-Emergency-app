/// responder_contributor.dart
///
/// Contributor that loads contact responders and appends them to the packet.

library;

import 'package:elly/features/emergency/packet/domain/entities/responder_section.dart';
import 'package:elly/features/emergency/packet/data/services/packet_contributor.dart';
import 'package:elly/features/emergency/packet/data/services/timeline_service.dart';

class ResponderContributor implements PacketContributor {
  const ResponderContributor({
    required Future<List<EmergencyResponder>> Function() fetchResponders,
    required TimelineService timelineService,
  })  : _fetchResponders = fetchResponders,
        _timelineService = timelineService;

  final Future<List<EmergencyResponder>> Function() _fetchResponders;
  final TimelineService _timelineService;

  @override
  Future<void> contribute(EmergencyPacketBuilderContext context) async {
    final list = await _fetchResponders();
    context.responders = ResponderSection(responders: list);

    _timelineService.append(
      title: 'Contacts Loaded',
      description: '${list.length} emergency contacts prepped for notification escalation.',
    );
  }
}
