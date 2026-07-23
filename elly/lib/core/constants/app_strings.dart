/// app_strings.dart
///
/// Centralised string constants for the ELLY application.
/// No UI string should be hardcoded in widget files.
/// Localisation (ARB / Flutter intl) can replace these constants in a later
/// phase without touching any widget code.

library;

/// Strings used across the Emergency SOS feature.
abstract final class AppStrings {
  // ── App ─────────────────────────────────────────────────────────────────
  static const String appName = 'Elly SOS';
  static const String appTagline = 'Your personal safety companion';

  // ── Home ─────────────────────────────────────────────────────────────────
  static const String sosButtonLabel = 'SOS';
  static const String sosButtonSubtext = 'Emergency';
  static const String sosButtonSemanticLabel =
      'Emergency SOS button. Tap to send an emergency alert.';

  // ── Emergency Confirmation Page ───────────────────────────────────────────
  static const String confirmationPageTitle = 'Emergency Check';
  static const String confirmationPageAppLabel = 'ELLY';
  static const String confirmationPageMessage = 'Are you safe right now?';
  static const String confirmationPageSubtext =
      'If you don\'t respond, Emergency SOS will activate automatically.';
  static const String confirmationYesSafe = 'Yes, I\'m Safe';
  static const String confirmationNeedHelp = 'No, I Need Help';
  static const String confirmationYesSafeSemanticLabel =
      'I am safe. Stop the countdown and cancel the emergency alert.';
  static const String confirmationNeedHelpSemanticLabel =
      'I need help. Activate Emergency SOS immediately.';
  static const String confirmationSafeSuccessTitle = 'You\'re Safe!';
  static const String confirmationSafeSuccessSubtext =
      'Emergency SOS has been cancelled.\nStay safe.';
  static const String secondsLabel = 'seconds';

  // ── Legacy Confirmation Sheet (kept for backward compat) ─────────────────
  static const String confirmationTitle = 'Emergency SOS';
  static const String confirmationDescription =
      'Do you want to send an emergency alert?';
  static const String confirmationCancel = 'Cancel';
  static const String confirmationActivate = 'Activate SOS';
  static const String confirmationActivateSemanticLabel =
      'Activate emergency SOS. This will start a countdown and notify your '
      'emergency contacts.';

  // ── Countdown ─────────────────────────────────────────────────────────────
  static const String countdownTitle = 'SOS will be activated.';
  static const String countdownCancel = 'Cancel';
  static const String countdownCancelSemanticLabel =
      'Cancel emergency SOS countdown and return to home.';

  // ── Activated ─────────────────────────────────────────────────────────────
  static const String activatedTitle = 'SOS Activated';
  static const String activatedDescription = 'Emergency workflow started.';
  static const String activatedReturnHome = 'Return Home';
  static const String activatedReturnHomeSemanticLabel =
      'Emergency SOS is active. Tap to return to the home screen.';

  // ── Accessibility ─────────────────────────────────────────────────────────
  static const String countdownSemanticPrefix = 'Countdown:';
  static const String successAnimationSemanticLabel =
      'Emergency SOS successfully activated.';
}
