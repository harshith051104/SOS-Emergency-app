/// confirmation_error.dart
///
/// Strongly typed error categories and exception class for Confirmation Engine.

library;

enum ConfirmationErrorCategory {
  timeout,
  invalidState,
  processingFailure,
}

class ConfirmationError implements Exception {
  const ConfirmationError(this.category, this.message);

  final ConfirmationErrorCategory category;
  final String message;

  @override
  String toString() => 'ConfirmationError[${category.name}]: $message';
}
