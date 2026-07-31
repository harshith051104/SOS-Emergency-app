/// emergency_alert_10s_sheet.dart
///
/// 10-second emergency confirmation alert sheet.
/// Features:
///   - 10-second active visual countdown
///   - Audio alert / siren feedback
///   - Repeating haptic vibration
///   - Non-dismissible timer display
///   - Direct Native Call (ACTION_CALL) to 112 on timeout or tap

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/sos/data/services/native_call_service.dart';
import 'package:elly/features/emergency/sos_circle/data/channels/device_sim_sms_channel.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/sos_notification_request.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/emergency_contact.dart';
import 'package:elly/features/emergency/sos_circle/presentation/providers/sos_circle_providers.dart';
import 'package:elly/features/emergency/packet/presentation/providers/packet_providers.dart';
import 'package:elly/features/emergency/packet/data/services/location_service.dart';
import 'package:elly/features/emergency/packet/domain/builder/emergency_data_packet_builder.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';
import 'package:elly/features/emergency/health_passport/presentation/providers/health_passport_providers.dart';
import 'package:elly/features/emergency/session/presentation/providers/session_providers.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/global/presentation/providers/global_providers.dart';
import 'package:elly/features/emergency/sos/data/services/alert_sound_vibration_service.dart';

class EmergencyAlert10sSheet extends ConsumerStatefulWidget {
  const EmergencyAlert10sSheet({
    super.key,
    required this.onCancelled,
    this.onConfirmed,
    this.emergencyNumber = '112',
    this.triggerReason = 'Voice Wake-Word / SOS Triggered',
  });

  final VoidCallback onCancelled;
  final VoidCallback? onConfirmed;
  final String emergencyNumber;
  final String triggerReason;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onCancelled,
    VoidCallback? onConfirmed,
    String emergencyNumber = '112',
    String triggerReason = 'Voice Wake-Word / SOS Triggered',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => EmergencyAlert10sSheet(
        onCancelled: onCancelled,
        onConfirmed: onConfirmed,
        emergencyNumber: emergencyNumber,
        triggerReason: triggerReason,
      ),
    );
  }

  @override
  ConsumerState<EmergencyAlert10sSheet> createState() => _EmergencyAlert10sSheetState();
}

class _EmergencyAlert10sSheetState extends ConsumerState<EmergencyAlert10sSheet>
    with SingleTickerProviderStateMixin {
  int _secondsRemaining = 10;
  Timer? _timer;
  late AnimationController _pulseController;
  bool _isDispatching = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    AlertSoundVibrationService.startAlertSequence(
      spokenText: 'Emergency alert! Direct call to ${widget.emergencyNumber} in 10 seconds.',
    );
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _dispatchEmergencyCall();
      }
    });
  }

  Future<void> _dispatchEmergencyCall() async {
    if (_isDispatching) return;
    setState(() {
      _isDispatching = true;
    });

    _cleanupMedia();
    appLogger.info('EmergencyAlert10sSheet: 10s countdown elapsed! Dispatching direct native call & emergency SIM SMS packet to ${widget.emergencyNumber} and SOS Circle members');

    widget.onConfirmed?.call();

    // 1. Send Direct SIM SMS Emergency Packet via DeviceSimSmsChannel
    try {
      final smsChannel = DeviceSimSmsChannel();
      final now = DateTime.now();

      final emergencyContact = EmergencyContact(
        id: 'emergency_line',
        fullName: 'Emergency Service',
        relationship: 'Official Line',
        primaryPhone: widget.emergencyNumber,
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final circleContacts = ref.read(sosCircleControllerProvider).contacts;
      final allContacts = [
        emergencyContact,
        ...circleContacts.where((c) => c.isEnabled && c.primaryPhone.isNotEmpty),
      ];

      var realPacket = ref.read(emergencyDataPacketProvider);

      // Fetch live GPS location coordinates & reverse-geocoded address
      String? locationStr;
      try {
        final loc = await const LocationService().getCurrentLocation();
        if (loc.latitude != null && loc.longitude != null) {
          final liveTelemetry = TelemetryPoint(
            latitude: loc.latitude!,
            longitude: loc.longitude!,
            altitude: 0.0,
            accuracy: 5.0,
            heading: 0.0,
            speed: 0.0,
            timestamp: now,
          );

          realPacket = EmergencyDataPacketBuilder.build(
            context: ref.read(emergencyContextProvider),
            snapshot: ref.read(sessionSnapshotProvider),
            passport: ref.read(healthPassportControllerProvider).passport,
            location: liveTelemetry,
            circle: ref.read(sosCircleStateProvider),
            networkState: ref.read(networkStateProvider),
            crossBorderContext: ref.read(crossBorderControllerProvider),
          );

          locationStr =
              'GPS: ${loc.latitude!.toStringAsFixed(6)}, ${loc.longitude!.toStringAsFixed(6)}\nMaps: https://maps.google.com/?q=${loc.latitude!.toStringAsFixed(6)},${loc.longitude!.toStringAsFixed(6)}\nAddress: ${loc.address}';
        } else if (loc.address.isNotEmpty) {
          locationStr = 'GPS: ${loc.address}';
        }
      } catch (e) {
        appLogger.warning('EmergencyAlert10sSheet: Location fetch error: $e');
      }

      final request = SOSNotificationRequest(
        dispatchId: 'disp_${now.millisecondsSinceEpoch}',
        sessionId: realPacket.sessionId,
        emergencyType: 'Emergency Dispatch',
        selectedService: 'NATIVE_DIALER',
        triggeredAt: now,
        contacts: allContacts,
        currentLocation: locationStr,
        emergencyPacket: realPacket,
      );

      for (final contact in allContacts) {
        appLogger.info('EmergencyAlert10sSheet: Sending SIM SMS packet to ${contact.fullName} (${contact.primaryPhone})');
        await smsChannel.send(request, contact);
      }
    } catch (e) {
      appLogger.warning('EmergencyAlert10sSheet: DeviceSimSmsChannel dispatch error: $e');
    }

    // 2. Place direct native ACTION_CALL to emergency number
    await NativeCallService.makeDirectCall(number: widget.emergencyNumber);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _cleanupMedia() {
    _timer?.cancel();
    _pulseController.stop();
    AlertSoundVibrationService.stopAlertSequence();
  }

  @override
  void dispose() {
    _cleanupMedia();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsRemaining / 10.0;

    return PopScope(
      canPop: false, // Non-dismissible sheet during countdown
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Pulsing Warning Icon + Alert Banner
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.sosPrimary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.sosPrimary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: AppColors.sosPrimary,
                      size: 42,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Header Title
            const Text(
              'EMERGENCY SOS CONFIRMATION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.sosPrimary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              widget.triggerReason,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Large 10-Second Visual Timer Circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFFFFE5EA),
                    color: AppColors.sosPrimary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_secondsRemaining',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.sosPrimary,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'SECONDS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Direct emergency call & SOS alert will trigger automatically when timer hits 0.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Cancel Button (False Alarm)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _cleanupMedia();
                      widget.onCancelled();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close_rounded, size: 20),
                    label: const Text('CANCEL SOS'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      foregroundColor: const Color(0xFF334155),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Call Now (Direct ACTION_CALL)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _dispatchEmergencyCall,
                    icon: const Icon(Icons.sos_rounded, size: 20),
                    label: const Text('NEED HELP NOW'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.sosPrimary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
