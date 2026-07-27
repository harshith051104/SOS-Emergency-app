/// app_clock.dart
///
/// Time source abstraction utility enabling deterministic testing and simulation.

library;

abstract class AppClock {
  static DateTime Function() _customClock = () => DateTime.now();

  static DateTime now() => _customClock();

  static void setMockClock(DateTime fixedTime) {
    _customClock = () => fixedTime;
  }

  static void resetClock() {
    _customClock = () => DateTime.now();
  }
}
