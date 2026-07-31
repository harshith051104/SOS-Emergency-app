/// device_sim_sms_channel.dart
///
/// Concrete [NotificationChannel] that sends emergency SOS alerts to SOS Circle
/// contacts via the device's own SIM card using [DeviceSimSmsService].
///
/// Behaviour:
///   • Requests SEND_SMS runtime permission before each dispatch batch.
///   • If permission is denied, the channel reports [NotificationDeliveryStatus.failed]
///     gracefully — no crash, no uncaught exception.
///   • On non-Android platforms the channel always returns failed so the caller
///     can fall back to the simulated channel.
///   • The SMS body is kept under 160 chars where possible; longer payloads are
///     automatically split into multipart SMS by Android SmsManager.

library;

import 'package:permission_handler/permission_handler.dart';
import 'package:elly/core/platform/device_sim_sms_service.dart';
import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/notification_channel.dart';
import '../../domain/entities/sos_notification_request.dart';
import '../../domain/entities/emergency_contact.dart';

class DeviceSimSmsChannel implements NotificationChannel {
  DeviceSimSmsChannel({DeviceSimSmsService? smsService})
      : _sms = smsService ?? const DeviceSimSmsService();

  final DeviceSimSmsService _sms;

  @override
  String get channelId => 'chn_device_sim_sms';

  @override
  String get channelName => 'Device SIM SMS';

  @override
  Future<ChannelResult> send(
    SOSNotificationRequest request,
    EmergencyContact contact,
  ) async {
    final timestamp = DateTime.now();

    // ── 1. Platform guard ────────────────────────────────────────────────────
    if (!_sms.isSupported) {
      appLogger.warning(
        'DeviceSimSmsChannel: Platform not supported — skipping SIM SMS for ${contact.fullName}.',
      );
      return ChannelResult(
        channelId: channelId,
        status: NotificationDeliveryStatus.failed,
        timestamp: timestamp,
        failureReason: 'Platform does not support Device SIM SMS',
      );
    }

    // ── 2. Runtime permission check ─────────────────────────────────────────
    final permStatus = await Permission.sms.status;
    if (!permStatus.isGranted) {
      appLogger.info('DeviceSimSmsChannel: Requesting SEND_SMS permission...');
      final requested = await Permission.sms.request();
      if (!requested.isGranted) {
        appLogger.warning(
          'DeviceSimSmsChannel: SEND_SMS permission denied for ${contact.fullName}.',
        );
        return ChannelResult(
          channelId: channelId,
          status: NotificationDeliveryStatus.failed,
          timestamp: DateTime.now(),
          failureReason: 'SEND_SMS permission denied by user',
        );
      }
    }

    // ── 3. Build compact SMS body ────────────────────────────────────────────
    final body = _buildSmsBody(request, contact);

    // ── 4. Dispatch via SIM ──────────────────────────────────────────────────
    appLogger.info(
      'DeviceSimSmsChannel: Dispatching SIM SMS → ${contact.primaryPhone} (${contact.fullName})',
    );

    final sent = await _sms.sendSms(to: contact.primaryPhone, body: body);

    if (sent) {
      appLogger.info(
        'DeviceSimSmsChannel: SMS queued ✓ → ${contact.fullName} (${contact.primaryPhone})',
      );
      return ChannelResult(
        channelId: channelId,
        status: NotificationDeliveryStatus.delivered,
        timestamp: DateTime.now(),
        messageId: 'sms_${DateTime.now().millisecondsSinceEpoch}_${contact.id}',
      );
    } else {
      appLogger.error(
        'DeviceSimSmsChannel: SMS dispatch failed for ${contact.fullName}',
      );
      return ChannelResult(
        channelId: channelId,
        status: NotificationDeliveryStatus.failed,
        timestamp: DateTime.now(),
        failureReason: 'SmsManager returned failure for ${contact.primaryPhone}',
      );
    }
  }

  // ── SMS Body Builder ────────────────────────────────────────────────────────

  String _buildSmsBody(SOSNotificationRequest request, EmergencyContact contact) {
    final pkt = request.emergencyPacket;
    final buf = StringBuffer();

    // ── Header ──────────────────────────────────────────────────────────────
    buf.writeln('🚨 SOS EMERGENCY ALERT — ELLY');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');

    // ── Who needs help ──────────────────────────────────────────────────────
    if (pkt != null) {
      buf.writeln('PATIENT: ${pkt.name}, ${pkt.age} yrs, ${pkt.bloodGroup}');
    }
    buf.writeln('CONTACT: ${contact.fullName} (${contact.relationship})');

    // ── Session & Time ──────────────────────────────────────────────────────
    buf.writeln('SESSION: ${pkt?.sessionId ?? request.sessionId}');
    buf.writeln('TIME: ${_fmtTime(request.triggeredAt)}');
    buf.writeln('STATUS: ${pkt?.emergencyState ?? 'ACTIVE'} | ${pkt?.currentSeverity ?? 'CRITICAL'}');

    // ── Location ────────────────────────────────────────────────────────────
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('📍 LOCATION');
    if (pkt != null && (pkt.latitude != 0.0 || pkt.longitude != 0.0)) {
      buf.writeln('GPS: ${pkt.latitude.toStringAsFixed(6)}, ${pkt.longitude.toStringAsFixed(6)}');
      buf.writeln('Maps: https://maps.google.com/?q=${pkt.latitude.toStringAsFixed(6)},${pkt.longitude.toStringAsFixed(6)}');
      if (pkt.address != null && pkt.address!.isNotEmpty) {
        buf.writeln('Address: ${pkt.address}');
      }
      if (pkt.altitude > 0) {
        buf.writeln('Altitude: ${pkt.altitude.toStringAsFixed(1)} m');
      }
      if (pkt.accuracy > 0) {
        buf.writeln('Accuracy: ±${pkt.accuracy.toStringAsFixed(1)} m');
      }
      if (pkt.speed > 0) {
        buf.writeln('Speed: ${(pkt.speed * 3.6).toStringAsFixed(1)} km/h');
      }
    } else if (request.currentLocation != null) {
      buf.writeln(request.currentLocation);
    } else {
      buf.writeln('GPS: Locating...');
    }

    // ── Medical Summary ─────────────────────────────────────────────────────
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('🏥 MEDICAL');
    if (pkt != null) {
      buf.writeln('Blood: ${pkt.bloodGroup}');
      buf.writeln('Allergies: ${pkt.allergies.isNotEmpty ? pkt.allergies.join(', ') : 'None known'}');
      buf.writeln('Medications: ${pkt.medications.isNotEmpty ? pkt.medications.join(', ') : 'None'}');
      if (pkt.chronicConditions.isNotEmpty) {
        buf.writeln('Conditions: ${pkt.chronicConditions.join(', ')}');
      }
      if (pkt.physician != null && pkt.physician!.isNotEmpty) {
        buf.writeln('Physician: ${pkt.physician}');
      }
      if (pkt.emergencyNotes.isNotEmpty) {
        buf.writeln('Notes: ${pkt.emergencyNotes}');
      }
    }

    // ── Emergency Service ───────────────────────────────────────────────────
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('🆘 DISPATCH');
    buf.writeln('Service: ${request.selectedService}');
    buf.writeln('Type: ${request.emergencyType}');
    if (pkt != null) {
      buf.writeln('Emergency Line: ${pkt.localEmergencyNumber}');
      buf.writeln('Country: ${pkt.countryCode}${pkt.isRoaming ? ' (ROAMING)' : ''}');
    }

    // ── Device Status ───────────────────────────────────────────────────────
    if (pkt != null) {
      buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('📱 DEVICE');
      buf.writeln('Battery: ${pkt.deviceInfo.batteryLevel}%');
      buf.writeln('Network: ${pkt.deviceInfo.networkState.toUpperCase()}');
      buf.writeln('Packet: ${pkt.packetId} (v${pkt.packetVersion}, seq ${pkt.sequenceNumber})');
    }

    // ── Footer ──────────────────────────────────────────────────────────────
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.write('Please respond immediately. Sent via ELLY SOS.');

    return buf.toString();
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mo-$d $h:$m:$s UTC';
  }
}
