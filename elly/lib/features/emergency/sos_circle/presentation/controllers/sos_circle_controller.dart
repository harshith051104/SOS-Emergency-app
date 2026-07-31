/// sos_circle_controller.dart
///
/// Master presentation controller for the SOS Circle feature managing contact CRUD,
/// domain validations, and coordinating notification requests with the Communication Engine.

library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/utils/app_logger.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/emergency_contact.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/sos_notification_request.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/sos_notification_result.dart';
import 'package:elly/features/emergency/sos_circle/domain/repositories/sos_circle_repository.dart';
import 'package:elly/features/emergency/packet/presentation/providers/packet_providers.dart';



@immutable
class SOSCircleState {
  const SOSCircleState({
    this.contacts = const [],
    this.isLoading = false,
    this.validationError,
    this.lastNotificationResult,
    this.isNotifying = false,
  });

  final List<EmergencyContact> contacts;
  final bool isLoading;
  final String? validationError;
  final SOSNotificationResult? lastNotificationResult;
  final bool isNotifying;

  SOSCircleState copyWith({
    List<EmergencyContact>? contacts,
    bool? isLoading,
    String? validationError,
    SOSNotificationResult? lastNotificationResult,
    bool? isNotifying,
    bool clearValidationError = false,
  }) {
    return SOSCircleState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      validationError: clearValidationError ? null : (validationError ?? this.validationError),
      lastNotificationResult: lastNotificationResult ?? this.lastNotificationResult,
      isNotifying: isNotifying ?? this.isNotifying,
    );
  }
}

class SOSCircleController extends StateNotifier<SOSCircleState> {
  SOSCircleController(this._repository, this._ref) : super(const SOSCircleState()) {
    loadContacts();
  }

  final SOSCircleRepository _repository;
  final Ref _ref;

  Ref get ref => _ref;

  /// Loads emergency contacts from the repository into presentation state.
  Future<void> loadContacts() async {
    state = state.copyWith(isLoading: true, clearValidationError: true);
    try {
      final contacts = await _repository.getContacts();
      state = state.copyWith(contacts: contacts, isLoading: false);
      appLogger.info('SOSCircleController: Successfully loaded ${contacts.length} contacts.');
    } catch (e, st) {
      appLogger.error('SOSCircleController: Failed loading contacts', e, st);
      state = state.copyWith(isLoading: false, validationError: e.toString());
    }
  }

  /// Adds a new contact after domain validation.
  Future<bool> addContact({
    required String fullName,
    required String relationship,
    required String primaryPhone,
    String? secondaryPhone,
    String? email,
    bool isPrimaryContact = false,
    int priority = 1,
  }) async {
    final now = DateTime.now();

    // Auto-assign primary if this is the very first contact in the circle
    final effectiveIsPrimary = isPrimaryContact || state.contacts.isEmpty;

    final newContact = EmergencyContact(
      id: 'cnt_${now.millisecondsSinceEpoch}',
      fullName: fullName,
      relationship: relationship,
      primaryPhone: primaryPhone,
      secondaryPhone: secondaryPhone,
      email: email,
      priority: priority,
      isPrimaryContact: effectiveIsPrimary,
      createdAt: now,
      updatedAt: now,
    );

    // Build the prospective full list for validation (existing contacts with
    // isPrimary cleared if the new one will be primary, then append new contact)
    var prospectiveList = List<EmergencyContact>.from(state.contacts);
    if (effectiveIsPrimary) {
      prospectiveList = prospectiveList
          .map((c) => c.copyWith(isPrimaryContact: false))
          .toList();
    }
    prospectiveList.add(newContact);

    final validation = _repository.validateContacts(prospectiveList);
    if (!validation.isValid) {
      state = state.copyWith(validationError: validation.errorMessage);
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, clearValidationError: true);

      // Demote ALL existing primaries in the repository first
      if (effectiveIsPrimary) {
        for (final c in state.contacts) {
          if (c.isPrimaryContact) {
            await _repository.updateContact(c.copyWith(isPrimaryContact: false));
          }
        }
      }

      await _repository.saveContact(newContact);
      await loadContacts();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, validationError: e.toString());
      return false;
    }
  }

  /// Updates an existing contact.
  Future<bool> updateContact(EmergencyContact contact) async {
    var updatedList = List<EmergencyContact>.from(state.contacts);
    final index = updatedList.indexWhere((c) => c.id == contact.id);
    if (index == -1) return false;

    if (contact.isPrimaryContact) {
      updatedList = updatedList.map((c) => c.id == contact.id ? contact : c.copyWith(isPrimaryContact: false)).toList();
    } else {
      updatedList[index] = contact;
    }

    final validation = _repository.validateContacts(updatedList);
    if (!validation.isValid) {
      state = state.copyWith(validationError: validation.errorMessage);
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, clearValidationError: true);
      if (contact.isPrimaryContact) {
        for (final c in state.contacts) {
          if (c.id != contact.id && c.isPrimaryContact) {
            await _repository.updateContact(c.copyWith(isPrimaryContact: false));
          }
        }
      }
      await _repository.updateContact(contact);
      await loadContacts();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, validationError: e.toString());
      return false;
    }
  }

  /// Deletes a contact.
  Future<bool> deleteContact(String id) async {
    final updatedList = state.contacts.where((c) => c.id != id).toList();
    final validation = _repository.validateContacts(updatedList);
    if (!validation.isValid) {
      state = state.copyWith(validationError: validation.errorMessage);
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, clearValidationError: true);
      await _repository.deleteContact(id);
      await loadContacts();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, validationError: e.toString());
      return false;
    }
  }

  /// Toggles contact enabled status.
  Future<bool> toggleContactEnabled(String id) async {
    final contact = state.contacts.cast<EmergencyContact?>().firstWhere(
          (c) => c != null && c.id == id,
          orElse: () => null,
        );
    if (contact == null) return false;

    final updated = contact.copyWith(isEnabled: !contact.isEnabled);
    return updateContact(updated);
  }

  /// Sets a designated contact as Primary.
  Future<bool> setPrimaryContact(String id) async {
    final contact = state.contacts.cast<EmergencyContact?>().firstWhere(
          (c) => c != null && c.id == id,
          orElse: () => null,
        );
    if (contact == null) return false;

    final updated = contact.copyWith(isPrimaryContact: true);
    return updateContact(updated);
  }

  /// Reorders contacts list dynamically via Drag and Drop and updates priorities.
  Future<void> reorderContacts(int oldIndex, int newIndex) async {
    final list = List<EmergencyContact>.from(state.contacts);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Re-assign priorities 1..N based on new order
    final reorderedList = <EmergencyContact>[];
    for (int i = 0; i < list.length; i++) {
      reorderedList.add(list[i].copyWith(
        priority: i + 1,
        isPrimaryContact: i == 0, // First priority becomes primary
      ));
    }

    state = state.copyWith(contacts: reorderedList);
    try {
      for (final c in reorderedList) {
        await _repository.updateContact(c);
      }
    } catch (e) {
      appLogger.error('SOSCircleController: Failed saving reordered contacts', e);
    }
  }



  /// Executes SOS emergency notifications for enabled contacts.
  Future<SOSNotificationResult?> triggerSOSNotifications({
    required String sessionId,
    required String emergencyType,
    required String selectedService,
    String? currentLocation,
    String? healthPassportReference,
  }) async {
    final validation = _repository.validateContacts(state.contacts);
    if (!validation.isValid) {
      state = state.copyWith(validationError: validation.errorMessage);
      appLogger.warning('SOSCircleController: Notification trigger blocked - ${validation.errorMessage}');
      return null;
    }

    // Read the live real-time emergency data packet from the backend engines
    final livePacket = _ref.read(emergencyDataPacketProvider);

    final request = SOSNotificationRequest(
      dispatchId: 'dsp_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      emergencyType: emergencyType,
      selectedService: selectedService,
      triggeredAt: DateTime.now(),
      contacts: state.contacts,
      currentLocation: currentLocation,
      healthPassportReference: healthPassportReference,
      emergencyPacket: livePacket,
    );

    state = state.copyWith(isNotifying: true, clearValidationError: true);
    final result = await _repository.notifyContacts(request);
    state = state.copyWith(isNotifying: false, lastNotificationResult: result);
    return result;
  }
}
