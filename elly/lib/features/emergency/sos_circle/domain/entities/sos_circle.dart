/// sos_circle.dart
///
/// Immutable domain entity representing the complete SOS Circle state and stats.

library;

import 'package:flutter/foundation.dart';
import 'emergency_contact.dart';

@immutable
class SOSCircle {
  const SOSCircle({
    required this.contacts,
    required this.totalContacts,
    required this.enabledContacts,
    this.primaryContactId,
  });

  final List<EmergencyContact> contacts;
  final int totalContacts;
  final int enabledContacts;
  final String? primaryContactId;

  factory SOSCircle.fromContacts(List<EmergencyContact> list) {
    final enabled = list.where((c) => c.isEnabled).length;
    final primary = list.cast<EmergencyContact?>().firstWhere(
          (c) => c != null && c.isPrimaryContact,
          orElse: () => null,
        );

    return SOSCircle(
      contacts: List.unmodifiable(list),
      totalContacts: list.length,
      enabledContacts: enabled,
      primaryContactId: primary?.id,
    );
  }

  EmergencyContact? get primaryContact {
    if (primaryContactId == null) return null;
    return contacts.cast<EmergencyContact?>().firstWhere(
          (c) => c != null && c.id == primaryContactId,
          orElse: () => null,
        );
  }
}
