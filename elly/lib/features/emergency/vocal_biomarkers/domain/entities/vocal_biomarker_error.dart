/// vocal_biomarker_error.dart
///
/// Strongly typed error categories and exception class for Vocal Biomarker Analysis.

library;

enum VocalBiomarkerErrorCategory {
  insufficientAudio,
  initializationFailure,
  timeout,
  featureExtractionFailure,
}

class VocalBiomarkerError implements Exception {
  const VocalBiomarkerError(this.category, this.message);

  final VocalBiomarkerErrorCategory category;
  final String message;

  @override
  String toString() => 'VocalBiomarkerError[${category.name}]: $message';
}
