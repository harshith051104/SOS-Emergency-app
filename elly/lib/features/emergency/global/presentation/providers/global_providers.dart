/// global_providers.dart
///
/// Riverpod dependency injection definitions exposing CrossBorderController,
/// active CountryProfile, and regional emergency services directory.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/global/domain/entities/cross_border_context.dart';
import 'package:elly/features/emergency/global/domain/entities/country_profile.dart';
import 'package:elly/features/emergency/global/presentation/controllers/cross_border_controller.dart';

final crossBorderControllerProvider =
    StateNotifierProvider<CrossBorderController, CrossBorderContext>((ref) {
  return CrossBorderController(ref);
});

final activeCountryProfileProvider = Provider<CountryProfile>((ref) {
  final context = ref.watch(crossBorderControllerProvider);
  return context.currentCountry;
});
