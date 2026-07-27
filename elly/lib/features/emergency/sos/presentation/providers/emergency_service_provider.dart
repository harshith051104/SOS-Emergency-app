/// emergency_service_provider.dart
///
/// Single source of truth managing emergency service selection state,
/// loading available services, single-selection validation, and event emission.

library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/emergency_service_model.dart';
import '../../domain/repositories/emergency_service_repository.dart';
import '../../data/repositories/emergency_service_repository_impl.dart';

final emergencyServiceRepositoryProvider = Provider<EmergencyServiceRepository>((ref) {
  return EmergencyServiceRepositoryImpl();
});

class EmergencyServiceSelectionState {
  const EmergencyServiceSelectionState({
    this.services = const [],
    this.selectedService,
    this.isLoading = false,
    this.completedResult,
  });

  final List<EmergencyService> services;
  final EmergencyService? selectedService;
  final bool isLoading;
  final EmergencySelectionResult? completedResult;

  bool get isServiceSelected => selectedService != null;

  EmergencyServiceSelectionState copyWith({
    List<EmergencyService>? services,
    EmergencyService? selectedService,
    bool? isLoading,
    EmergencySelectionResult? completedResult,
  }) {
    return EmergencyServiceSelectionState(
      services: services ?? this.services,
      selectedService: selectedService ?? this.selectedService,
      isLoading: isLoading ?? this.isLoading,
      completedResult: completedResult ?? this.completedResult,
    );
  }
}

final emergencyServiceProvider =
    StateNotifierProvider<EmergencyServiceNotifier, EmergencyServiceSelectionState>((ref) {
  final repo = ref.watch(emergencyServiceRepositoryProvider);
  return EmergencyServiceNotifier(repo);
});

class EmergencyServiceNotifier extends StateNotifier<EmergencyServiceSelectionState> {
  EmergencyServiceNotifier(this._repository) : super(const EmergencyServiceSelectionState()) {
    loadServices();
  }

  final EmergencyServiceRepository _repository;
  final _eventController = StreamController<EmergencySelectionEvent>.broadcast();

  Stream<EmergencySelectionEvent> get eventStream => _eventController.stream;

  Future<void> loadServices({String countryCode = 'IN'}) async {
    state = state.copyWith(isLoading: true);
    final list = await _repository.getAvailableServices(countryCode: countryCode);
    state = state.copyWith(services: list, isLoading: false);
  }

  void selectService(EmergencyService service) {
    state = state.copyWith(selectedService: service);
    _eventController.add(ServiceSelectedEvent(service: service));
  }

  EmergencySelectionResult? confirmSelection({String triggerSource = 'MANUAL SOS'}) {
    if (state.selectedService == null) return null;

    final result = EmergencySelectionResult(
      selectedService: state.selectedService!,
      triggerSource: triggerSource,
      selectedAt: DateTime.now(),
    );

    state = state.copyWith(completedResult: result);
    _eventController.add(SelectionCompletedEvent(result: result));
    return result;
  }

  void clearSelection() {
    state = state.copyWith();
  }

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}
