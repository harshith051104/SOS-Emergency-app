/// developer_mode_provider.dart
///
/// Riverpod state provider managing the UI view mode (User Mode vs Developer Flight Recorder Mode).

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

final isDeveloperModeProvider = StateProvider<bool>((ref) => false);
