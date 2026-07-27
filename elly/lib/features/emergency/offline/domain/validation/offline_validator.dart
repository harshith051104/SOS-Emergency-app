/// offline_validator.dart
///
/// Pure domain validator enforcing queue consistency, payload integrity, and retry limit rules.

library;

import 'package:elly/features/emergency/offline/domain/entities/pending_operation.dart';

class OfflineValidationReport {
  const OfflineValidationReport._(this.isValid, this.warnings);

  factory OfflineValidationReport.valid() => const OfflineValidationReport._(true, []);

  factory OfflineValidationReport.invalid(List<String> warnings) => OfflineValidationReport._(false, warnings);

  final bool isValid;
  final List<String> warnings;
}

class OfflineValidator {
  static const int maxRetryLimit = 5;

  /// Validates a list of pending operations for duplicates, corruption, and retry limits.
  static OfflineValidationReport validateQueue(List<PendingOperation> queue) {
    final warnings = <String>[];
    final seenIds = <String>{};

    for (final op in queue) {
      if (seenIds.contains(op.id)) {
        warnings.add('Duplicate operation ID detected: ${op.id}');
      }
      seenIds.add(op.id);

      if (op.operationType.isEmpty) {
        warnings.add('Operation ${op.id} has empty operationType.');
      }

      if (op.retryAttempts > maxRetryLimit) {
        warnings.add('Operation ${op.id} exceeded maximum retry limit ($maxRetryLimit).');
      }
    }

    if (warnings.isNotEmpty) {
      return OfflineValidationReport.invalid(warnings);
    }
    return OfflineValidationReport.valid();
  }
}
