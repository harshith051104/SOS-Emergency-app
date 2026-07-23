/// location_contributor.dart
///
/// Contributor that gathers GPS/address info and appends it to the packet.

library;

import '../location_service.dart';
import '../packet_contributor.dart';
import '../timeline_service.dart';

class LocationContributor implements PacketContributor {
  const LocationContributor({
    required LocationService locationService,
    required TimelineService timelineService,
  })  : _locationService = locationService,
        _timelineService = timelineService;

  final LocationService _locationService;
  final TimelineService _timelineService;

  @override
  Future<void> contribute(EmergencyPacketBuilderContext context) async {
    final location = await _locationService.getCurrentLocation();
    context.location = location;

    final hasCoords = location.latitude != null && location.longitude != null;
    _timelineService.append(
      title: 'Location Retrieved',
      description: hasCoords
          ? 'Coords: [${location.latitude!.toStringAsFixed(4)}, ${location.longitude!.toStringAsFixed(4)}] (Accuracy: ${location.accuracy}).'
          : 'Failed: ${location.address}.',
    );
  }
}
