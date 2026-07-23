/// home_page_golden_test.dart
///
/// Golden tests for [HomePage] in both light and dark modes.
/// Run: flutter test --update-goldens   (to regenerate snapshots)
/// Run: flutter test                    (to assert against snapshots)

library;

import 'package:elly/features/emergency/sos/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  group('HomePage Goldens —', () {
    testGoldens('light mode', (tester) async {
      await tester.pumpWidgetBuilder(
        buildTestApp(const HomePage()),
        surfaceSize: const Size(390, 844), // iPhone 14 Pro
      );
      await tester.pump();

      await screenMatchesGolden(tester, 'home_page_light');
    });

    testGoldens('dark mode', (tester) async {
      await tester.pumpWidgetBuilder(
        Builder(
          builder: (context) => Theme(
            data: ThemeData.dark(useMaterial3: true),
            child: buildTestApp(const HomePage()),
          ),
        ),
        surfaceSize: const Size(390, 844),
      );
      await tester.pump();

      await screenMatchesGolden(tester, 'home_page_dark');
    });
  });
}
