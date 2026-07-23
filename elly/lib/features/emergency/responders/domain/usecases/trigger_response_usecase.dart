/// trigger_response_usecase.dart
///
/// Orchestrates building the [EmergencyResponsePlan] from the repository
/// and executing it via the [EmergencyResponseEngine].
///
/// Returns a [Stream] of [ResponseEngineUpdate] events so the caller
/// can subscribe to the live timeline.

library;

import '../repositories/responder_repository.dart';
import '../services/emergency_response_engine.dart';
import '../entities/responder.dart';
import '../enums/responder_type.dart';
import '../../../sos/domain/entities/emergency_event.dart';
import '../../../../../core/utils/emergency_number_resolver.dart';
import '../../../packet/data/services/location_service.dart';

/// Builds the response plan and executes the engine for a given [EmergencyEvent].
class TriggerResponseUseCase {
  const TriggerResponseUseCase({
    required ResponderRepository repository,
    required EmergencyResponseEngine engine,
    required LocationService locationService,
  })  : _repository = repository,
        _engine = engine,
        _locationService = locationService;

  final ResponderRepository _repository;
  final EmergencyResponseEngine _engine;
  final LocationService _locationService;

  /// Returns a stream of [ResponseEngineUpdate] events.
  ///
  /// If no enabled responders are configured, immediately yields a
  /// [failed] event and closes.
  Stream<ResponseEngineUpdate> call(EmergencyEvent event, {String? category}) async* {
    final allResponders = await _repository.getResponders();

    // Get live country code from GPS location
    String? liveCountryCode;
    try {
      final location = await _locationService.getCurrentLocation();
      liveCountryCode = location.isoCountryCode;
    } catch (_) {}

    final enabled = allResponders
        .where((r) => r.isEnabled && r.isActionable)
        .map((r) {
          if (r.type == ResponderType.emergencyService) {
            // Resolve service number based on category and live location country code
            final resolvedNum = EmergencyNumberResolver.resolveServiceNumber(
              category: category ?? 'universal',
              countryCode: liveCountryCode,
            );
            return r.copyWith(phoneNumber: resolvedNum);
          }
          return r;
        })
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    if (enabled.isEmpty) {
      yield ResponseEngineUpdate.failed(
        'No enabled responders configured. '
        'Please add emergency contacts in Settings → Responders.',
      );
      return;
    }

    final plan = EmergencyResponsePlan(responders: enabled);
    yield* _engine.execute(event: event, plan: plan);
  }
}
