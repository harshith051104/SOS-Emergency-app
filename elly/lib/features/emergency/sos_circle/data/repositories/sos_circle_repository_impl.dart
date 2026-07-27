/// sos_circle_repository_impl.dart
///
/// Data layer implementation of SOSCircleRepository backed by SharedPreferences local storage.

library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elly/core/utils/app_logger.dart';
import '../../domain/entities/emergency_contact.dart';
import '../../domain/entities/sos_circle.dart';
import '../../domain/entities/sos_notification_request.dart';
import '../../domain/entities/sos_notification_result.dart';
import '../../domain/repositories/sos_circle_repository.dart';
import '../../domain/validation/sos_circle_validator.dart';
import '../services/sos_notification_service.dart';

class SOSCircleRepositoryImpl implements SOSCircleRepository {
  SOSCircleRepositoryImpl({SOSNotificationService? notificationService})
      : _notificationService = notificationService ?? SOSNotificationService();

  static const String _storageKey = 'elly_sos_circle_contacts_v1';
  final SOSNotificationService _notificationService;

  @override
  Future<List<EmergencyContact>> getContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.trim().isEmpty) {
        final defaultContacts = _generateDefaultContacts();
        await _persistContacts(defaultContacts);
        return defaultContacts;
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final contacts = jsonList.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>)).toList();
      appLogger.info('SOSCircleRepositoryImpl: Loaded ${contacts.length} contacts from storage.');
      return contacts;
    } catch (e, st) {
      appLogger.error('SOSCircleRepositoryImpl: Failed loading contacts', e, st);
      final fallback = _generateDefaultContacts();
      return fallback;
    }
  }

  @override
  Future<SOSCircle> getSOSCircle() async {
    final list = await getContacts();
    return SOSCircle.fromContacts(list);
  }

  @override
  Future<void> saveContact(EmergencyContact contact) async {
    final currentList = await getContacts();
    final updatedList = List<EmergencyContact>.from(currentList)..add(contact);

    final validation = validateContacts(updatedList);
    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    await _persistContacts(updatedList);
    appLogger.info('SOSCircleRepositoryImpl: Contact saved - ${contact.fullName}');
  }

  @override
  Future<void> updateContact(EmergencyContact contact) async {
    final currentList = await getContacts();
    final index = currentList.indexWhere((c) => c.id == contact.id);
    if (index == -1) {
      throw Exception('Contact with ID ${contact.id} not found.');
    }

    final updatedList = List<EmergencyContact>.from(currentList);
    updatedList[index] = contact.copyWith(updatedAt: DateTime.now());

    final validation = validateContacts(updatedList);
    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    await _persistContacts(updatedList);
    appLogger.info('SOSCircleRepositoryImpl: Contact updated - ${contact.fullName}');
  }

  @override
  Future<void> deleteContact(String id) async {
    final currentList = await getContacts();
    final updatedList = currentList.where((c) => c.id != id).toList();

    final validation = validateContacts(updatedList);
    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    await _persistContacts(updatedList);
    appLogger.info('SOSCircleRepositoryImpl: Contact deleted - ID: $id');
  }

  @override
  Future<SOSNotificationResult> notifyContacts(SOSNotificationRequest request) async {
    return _notificationService.dispatchNotifications(request);
  }

  @override
  ValidationResult validateContacts(List<EmergencyContact> contacts) {
    return SOSCircleValidator.validateContacts(contacts);
  }

  Future<void> _persistContacts(List<EmergencyContact> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((c) => c.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  List<EmergencyContact> _generateDefaultContacts() {
    final now = DateTime.now();
    return [
      EmergencyContact(
        id: 'cnt_mom_01',
        fullName: 'Mom (Primary Contact)',
        relationship: 'Family',
        primaryPhone: '+1 800-555-0199',
        secondaryPhone: '+1 800-555-0198',
        email: 'mom.family@example.com',
        isPrimaryContact: true,
        createdAt: now,
        updatedAt: now,
      ),
      EmergencyContact(
        id: 'cnt_doc_02',
        fullName: 'Dr. Sarah Smith',
        relationship: 'Primary Care Doctor',
        primaryPhone: '+1 800-555-0188',
        email: 'dr.smith@medcare.org',
        priority: 2,
        createdAt: now,
        updatedAt: now,
      ),
      EmergencyContact(
        id: 'cnt_alex_03',
        fullName: 'Alex Johnson',
        relationship: 'Spouse / Guardian',
        primaryPhone: '+1 800-555-0177',
        priority: 3,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
