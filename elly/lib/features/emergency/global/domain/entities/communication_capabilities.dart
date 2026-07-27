/// communication_capabilities.dart
///
/// Feature capability flags defining regional emergency hardware & network dispatch capabilities.

library;

import 'package:flutter/foundation.dart';

@immutable
class CommunicationCapabilities {
  const CommunicationCapabilities({
    this.canCallEmergencyServices = true,
    this.canSendSMS = true,
    this.canUseInternet = true,
    this.canUseSatellite = false,
    this.canUseVoIP = true,
    this.supportsMedicalDispatch = true,
    this.supportsRealtimeLocationSharing = true,
  });

  final bool canCallEmergencyServices;
  final bool canSendSMS;
  final bool canUseInternet;
  final bool canUseSatellite;
  final bool canUseVoIP;
  final bool supportsMedicalDispatch;
  final bool supportsRealtimeLocationSharing;

  Map<String, dynamic> toJson() => {
        'canCallEmergencyServices': canCallEmergencyServices,
        'canSendSMS': canSendSMS,
        'canUseInternet': canUseInternet,
        'canUseSatellite': canUseSatellite,
        'canUseVoIP': canUseVoIP,
        'supportsMedicalDispatch': supportsMedicalDispatch,
        'supportsRealtimeLocationSharing': supportsRealtimeLocationSharing,
      };

  factory CommunicationCapabilities.fromJson(Map<String, dynamic> json) => CommunicationCapabilities(
        canCallEmergencyServices: json['canCallEmergencyServices'] as bool? ?? true,
        canSendSMS: json['canSendSMS'] as bool? ?? true,
        canUseInternet: json['canUseInternet'] as bool? ?? true,
        canUseSatellite: json['canUseSatellite'] as bool? ?? false,
        canUseVoIP: json['canUseVoIP'] as bool? ?? true,
        supportsMedicalDispatch: json['supportsMedicalDispatch'] as bool? ?? true,
        supportsRealtimeLocationSharing: json['supportsRealtimeLocationSharing'] as bool? ?? true,
      );
}
