/// sos_circle_validator.dart
///
/// Pure domain validation engine enforcing business rules for the SOS Circle.

library;

import 'package:elly/features/emergency/sos_circle/domain/entities/emergency_contact.dart';


class ValidationResult {
  const ValidationResult._(this.isValid, this.errorMessage);

  factory ValidationResult.success() => const ValidationResult._(true, null);
  factory ValidationResult.failure(String error) => ValidationResult._(false, error);

  final bool isValid;
  final String? errorMessage;
}

class SOSCircleValidator {
  static const int maxAllowedContacts = 10;

  /// Validates contact list integrity against domain rules.
  static ValidationResult validateContacts(List<EmergencyContact> contacts) {
    if (contacts.isEmpty) {
      return ValidationResult.failure('SOS Circle must contain at least 1 emergency contact.');
    }

    if (contacts.length > maxAllowedContacts) {
      return ValidationResult.failure('Maximum $maxAllowedContacts contacts allowed in SOS Circle.');
    }

    final enabledContacts = contacts.where((c) => c.isEnabled).toList();
    if (enabledContacts.isEmpty) {
      return ValidationResult.failure('At least one emergency contact must be enabled.');
    }

    // Rule: Exactly 1 primary contact required if circle is non-empty
    final primaryCount = contacts.where((c) => c.isPrimaryContact).length;
    if (primaryCount == 0) {
      return ValidationResult.failure('SOS Circle requires one designated Primary Contact.');
    }
    if (primaryCount > 1) {
      return ValidationResult.failure('Only one contact can be designated as Primary Contact.');
    }

    // Rule: Phone numbers must be unique
    final phoneSet = <String>{};
    for (final contact in contacts) {
      final sanitizedPrimary = _sanitizePhone(contact.primaryPhone);
      if (phoneSet.contains(sanitizedPrimary)) {
        return ValidationResult.failure('Duplicate phone number detected: ${contact.primaryPhone}');
      }
      phoneSet.add(sanitizedPrimary);

      if (contact.secondaryPhone != null && contact.secondaryPhone!.trim().isNotEmpty) {
        final sanitizedSecondary = _sanitizePhone(contact.secondaryPhone!);
        if (phoneSet.contains(sanitizedSecondary)) {
          return ValidationResult.failure('Duplicate secondary phone number detected: ${contact.secondaryPhone}');
        }
        phoneSet.add(sanitizedSecondary);
      }
    }

    // Rule: Email addresses must be unique
    final emailSet = <String>{};
    for (final contact in contacts) {
      if (contact.email != null && contact.email!.trim().isNotEmpty) {
        final sanitizedEmail = contact.email!.trim().toLowerCase();
        if (emailSet.contains(sanitizedEmail)) {
          return ValidationResult.failure('Duplicate email address detected: ${contact.email}');
        }
        emailSet.add(sanitizedEmail);
      }
    }

    return ValidationResult.success();
  }

  static String _sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
  }
}
