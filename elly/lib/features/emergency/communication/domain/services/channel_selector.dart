/// channel_selector.dart
///
/// Communication channel selection strategy service evaluating network connectivity and cross-border capabilities.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/offline/presentation/providers/offline_providers.dart';
import 'package:elly/features/emergency/global/presentation/providers/global_providers.dart';
import 'package:elly/features/emergency/communication/domain/entities/communication_request.dart';

class ChannelSelector {
  ChannelSelector(this._ref);

  final Ref _ref;

  List<String> selectChannels(CommunicationRequest request) {
    final netState = _ref.read(networkStateProvider);
    final globalContext = _ref.read(crossBorderControllerProvider);

    final isOnline = netState.name == 'online';
    final capabilities = globalContext.currentCountry.capabilities;

    final channels = <String>[];

    if (isOnline && capabilities.canUseInternet) {
      channels.add('PushNotification');
      if (capabilities.canSendSMS) channels.add('SMS');
      channels.add('Email');
    } else {
      if (capabilities.canSendSMS) channels.add('SMS');
      if (capabilities.canCallEmergencyServices) channels.add('PhoneCall');
    }

    // Always fallback to OfflineQueue if other channels fail
    channels.add('OfflineQueue');

    return channels;
  }
}
