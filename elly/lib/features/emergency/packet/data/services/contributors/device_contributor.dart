/// device_contributor.dart
///
/// Contributor that gathers device diagnostics and appends it to the packet.

library;

import '../device_service.dart';
import '../packet_contributor.dart';
import '../timeline_service.dart';

class DeviceContributor implements PacketContributor {
  const DeviceContributor({
    required DeviceService deviceService,
    required TimelineService timelineService,
  })  : _deviceService = deviceService,
        _timelineService = timelineService;

  final DeviceService _deviceService;
  final TimelineService _timelineService;

  @override
  Future<void> contribute(EmergencyPacketBuilderContext context) async {
    final telemetry = await _deviceService.getDeviceTelemetry();
    context.device = telemetry;

    _timelineService.append(
      title: 'Device Telemetry Retrieved',
      description: 'Battery: ${telemetry.batteryPercent}% (Charging: ${telemetry.isCharging}), Net: ${telemetry.connectionType.toUpperCase()}.',
    );
  }
}
