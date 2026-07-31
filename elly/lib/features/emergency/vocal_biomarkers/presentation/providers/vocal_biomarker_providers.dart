/// vocal_biomarker_providers.dart
///
/// Riverpod dependency injection providers for the Vocal Biomarkers feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/vocal_biomarker_config.dart';
import '../../domain/entities/vocal_biomarker_state.dart';
import '../../domain/entities/vocal_biomarker_telemetry.dart';
import '../../domain/interfaces/i_vocal_biomarker_analyzer.dart';
import '../../data/analyzers/feature_based_analyzer.dart';
import '../../data/services/vocal_biomarker_service.dart';
import '../controllers/vocal_biomarker_controller.dart';

/// Provider for Vocal Biomarker Configuration
final vocalBiomarkerConfigProvider = Provider<VocalBiomarkerConfig>((ref) {
  return const VocalBiomarkerConfig();
});

/// Provider for the active VocalBiomarkerAnalyzer implementation
final vocalBiomarkerAnalyzerProvider = Provider<VocalBiomarkerAnalyzer>((ref) {
  final analyzer = FeatureBasedAnalyzer();
  ref.onDispose(() => analyzer.dispose());
  return analyzer;
});

/// Provider for the VocalBiomarkerService
final vocalBiomarkerServiceProvider = Provider<VocalBiomarkerService>((ref) {
  final analyzer = ref.watch(vocalBiomarkerAnalyzerProvider);
  final config = ref.watch(vocalBiomarkerConfigProvider);
  final service = VocalBiomarkerService(analyzer: analyzer, config: config);
  ref.onDispose(() => service.dispose());
  return service;
});

/// StateNotifierProvider for the VocalBiomarkerController
final vocalBiomarkerControllerProvider =
    StateNotifierProvider<VocalBiomarkerController, VocalBiomarkerState>((ref) {
  final service = ref.watch(vocalBiomarkerServiceProvider);
  return VocalBiomarkerController(ref, service: service);
});

/// Provider for current Vocal Biomarker Telemetry
final vocalBiomarkerTelemetryProvider = Provider<VocalBiomarkerTelemetry>((ref) {
  return ref.watch(vocalBiomarkerControllerProvider).telemetry;
});
