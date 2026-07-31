/// i_vocal_biomarker_analyzer.dart
///
/// Interface defining the contract for acoustic feature extraction engines.

library;

import '../entities/vocal_biomarker_request.dart';
import '../entities/vocal_biomarker_result.dart';

abstract class VocalBiomarkerAnalyzer {
  /// Analyzes an incoming audio request and extracts objective acoustic features.
  Future<VocalBiomarkerResult> analyze(VocalBiomarkerRequest request);

  /// Releases any allocated resources or DSP buffers.
  void dispose();
}
