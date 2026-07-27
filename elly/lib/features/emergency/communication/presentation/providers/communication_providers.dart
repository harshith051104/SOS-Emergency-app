/// communication_providers.dart
///
/// Riverpod dependency injection definitions for ChannelSelector, CommunicationEngine, and CommunicationController.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/communication/domain/entities/communication_result.dart';
import 'package:elly/features/emergency/communication/domain/services/channel_selector.dart';
import 'package:elly/features/emergency/communication/domain/services/communication_engine.dart';
import 'package:elly/features/emergency/communication/presentation/controllers/communication_controller.dart';

export 'communication_provider.dart';

final channelSelectorProvider = Provider<ChannelSelector>((ref) {
  return ChannelSelector(ref);
});

final communicationEngineProvider = Provider<CommunicationEngine>((ref) {
  final selector = ref.watch(channelSelectorProvider);
  return CommunicationEngine(ref, selector);
});

final communicationControllerProvider =
    StateNotifierProvider<CommunicationController, CommunicationResult?>((ref) {
  final engine = ref.watch(communicationEngineProvider);
  return CommunicationController(engine);
});
