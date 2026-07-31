/// backend_config.dart
///
/// Centralised backend URL configuration for the Elly SOS app.
///
/// The backend URL is injected via --dart-define at build time so it works
/// for both Android emulator and physical devices.
///
/// Usage at build/run time:
///   # Android emulator (maps 10.0.2.2 → host machine localhost)
///   flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000
///
///   # Physical device (use your machine's LAN IP)
///   flutter run --dart-define=BACKEND_BASE_URL=http://192.168.1.X:8000
///
///   # Release (production server)
///   flutter run --release --dart-define=BACKEND_BASE_URL=https://api.elly-sos.app

library;

class BackendConfig {
  BackendConfig._();

  /// Base URL of the Elly SOS Python backend.
  /// Defaults to Android emulator's loopback alias for localhost.
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Full prefix for all v1 API routes.
  static const String v1 = '$baseUrl/v1';

  /// STT endpoints — matches backend/app/api/v1/stt.py
  static const String sttTranscribeSherpa = '$v1/stt/transcribe';
  static const String sttTranscribeGroq   = '$v1/stt/transcribe/groq';
  static const String sttTranscribeAuto   = '$v1/stt/transcribe/auto';
  static const String sttStatus           = '$v1/stt/status';
}
