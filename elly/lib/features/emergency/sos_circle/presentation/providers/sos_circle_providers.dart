/// sos_circle_providers.dart
///
/// Riverpod providers exposing repository, notification service, controller state,
/// contact lists, and event streams for the SOS Circle feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/sos_circle.dart';

import 'package:elly/features/emergency/sos_circle/domain/entities/sos_circle_event.dart';
import 'package:elly/features/emergency/sos_circle/domain/repositories/sos_circle_repository.dart';
import 'package:elly/features/emergency/sos_circle/data/repositories/sos_circle_repository_impl.dart';
import 'package:elly/features/emergency/sos_circle/data/services/sos_notification_service.dart';
import 'package:elly/features/emergency/sos_circle/presentation/controllers/sos_circle_controller.dart';


import 'package:elly/features/emergency/sos_circle/domain/entities/notification_channel.dart';

final notificationChannelsProvider = Provider<List<NotificationChannel>>((ref) {
  return [
    SimulatedNotificationChannel(),
  ];
});

final sosNotificationServiceProvider = Provider<SOSNotificationService>((ref) {
  final channels = ref.watch(notificationChannelsProvider);
  final service = SOSNotificationService(channels: channels);
  ref.onDispose(() => service.dispose());
  return service;
});


final sosCircleRepositoryProvider = Provider<SOSCircleRepository>((ref) {
  final service = ref.watch(sosNotificationServiceProvider);
  return SOSCircleRepositoryImpl(notificationService: service);
});

final sosCircleControllerProvider =
    StateNotifierProvider<SOSCircleController, SOSCircleState>((ref) {
  final repository = ref.watch(sosCircleRepositoryProvider);
  return SOSCircleController(repository, ref);
});

final sosCircleStreamProvider = StreamProvider<SOSCircleEvent>((ref) {
  final service = ref.watch(sosNotificationServiceProvider);
  return service.eventStream;
});

final sosCircleStateProvider = Provider<SOSCircle>((ref) {
  final state = ref.watch(sosCircleControllerProvider);
  return SOSCircle.fromContacts(state.contacts);
});
