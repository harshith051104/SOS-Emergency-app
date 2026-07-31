/// emergency_execution_error.dart
///
/// Strongly typed error categories and exception class for Phase 8.

library;

enum EmergencyExecutionErrorCategory {
  communicationFailure,
  permissionDenied,
  locationUnavailable,
  contactUnavailable,
  executionFailure,
}

class EmergencyExecutionError implements Exception {
  const EmergencyExecutionError(this.category, this.message);

  final EmergencyExecutionErrorCategory category;
  final String message;

  @override
  String toString() => 'EmergencyExecutionError[${category.name}]: $message';
}
