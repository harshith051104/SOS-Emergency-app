/// telemetry_providers.dart
///
/// Riverpod dependency injection definitions exposing TelemetrySources, TelemetryService,
/// TelemetryRepository, TelemetryController, location streams, quality filters, and current session state.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_point.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_session.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_event.dart';
import 'package:elly/features/emergency/telemetry/domain/entities/telemetry_source.dart';
import 'package:elly/features/emergency/telemetry/domain/repositories/telemetry_repository.dart';
import 'package:elly/features/emergency/telemetry/data/services/telemetry_service.dart';
import 'package:elly/features/emergency/telemetry/data/repositories/telemetry_repository_impl.dart';
import 'package:elly/features/emergency/telemetry/presentation/controllers/telemetry_controller.dart';

final telemetrySourcesProvider = Provider<List<TelemetrySource>>((ref) {
  final service = ref.watch(telemetryServiceProvider);
  return [
    GpsTelemetrySource(service),
    // Future plugins: AccelerometerSource(), GyroscopeSource(), WearableSource(), etc.
  ];
});

final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  final service = TelemetryService();
  ref.onDispose(() => service.dispose());
  return service;
});

final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  final service = ref.watch(telemetryServiceProvider);
  return TelemetryRepositoryImpl(service: service);
});

final telemetryControllerProvider =
    StateNotifierProvider<TelemetryController, TelemetrySession>((ref) {
  final repository = ref.watch(telemetryRepositoryProvider);
  return TelemetryController(repository);
});

final telemetryEventStreamProvider = StreamProvider<TelemetryEvent>((ref) {
  final service = ref.watch(telemetryServiceProvider);
  return service.eventStream;
});

final liveLocationStreamProvider = StreamProvider<TelemetryPoint>((ref) {
  final repository = ref.watch(telemetryRepositoryProvider);
  return repository.locationStream();
});

final latestTelemetryPointProvider = Provider<TelemetryPoint?>((ref) {
  final session = ref.watch(telemetryControllerProvider);
  return session.latestPoint;
});

final telemetryHistoryProvider = Provider<List<TelemetryPoint>>((ref) {
  final session = ref.watch(telemetryControllerProvider);
  return session.history;
});
