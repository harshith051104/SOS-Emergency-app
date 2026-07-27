/// health_passport_detail_sheet.dart
///
/// Full Emergency Health Passport detail view & editor modal sheet backed by Riverpod HealthPassportController.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/features/emergency/health_passport/presentation/providers/health_passport_providers.dart';

import 'package:elly/features/emergency/health_passport/domain/entities/emergency_health_profile.dart';

class HealthPassportDetailSheet extends ConsumerStatefulWidget {
  const HealthPassportDetailSheet({super.key});

  @override
  ConsumerState<HealthPassportDetailSheet> createState() => _HealthPassportDetailSheetState();
}

class _HealthPassportDetailSheetState extends ConsumerState<HealthPassportDetailSheet> {
  final _bloodGroupController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _organDonor = false;

  void _showEditProfileDialog(BuildContext context, EmergencyHealthProfile profile) {
    _bloodGroupController.text = profile.bloodGroup;
    _allergiesController.text = profile.allergies.join(', ');
    _medicationsController.text = profile.medications.join(', ');
    _conditionsController.text = profile.chronicConditions.join(', ');
    _notesController.text = profile.emergencyNotes;
    _organDonor = profile.organDonor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Edit Health Passport', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _bloodGroupController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Blood Group (e.g. O+, A-, B+)', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _allergiesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Allergies (comma separated)', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _medicationsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Medications (comma separated)', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _conditionsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Chronic Conditions', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Emergency Medical Notes', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Organ Donor', style: TextStyle(color: Colors.white, fontSize: 13)),
                  value: _organDonor,
                  activeTrackColor: Colors.purple,
                  onChanged: (val) => setDialogState(() => _organDonor = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () async {
                final updated = profile.copyWith(
                  bloodGroup: _bloodGroupController.text.trim().toUpperCase(),
                  allergies: _allergiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                  medications: _medicationsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                  chronicConditions: _conditionsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                  emergencyNotes: _notesController.text.trim(),
                  organDonor: _organDonor,
                );
                final success = await ref.read(healthPassportControllerProvider.notifier).updateProfile(updated);
                if (success && ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passportState = ref.watch(healthPassportControllerProvider);
    final passport = passportState.passport;
    final profile = passport?.profile;
    final validation = passportState.validationResult;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EMERGENCY HEALTH PASSPORT',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.purple, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Completeness Score: ${passport?.completenessScore ?? 90}%',
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (profile != null)
                    IconButton(
                      onPressed: () => _showEditProfileDialog(context, profile),
                      icon: const Icon(Icons.edit_rounded, color: Colors.purple),
                      tooltip: 'Edit Profile',
                    ),
                ],
              ),
              if (validation != null && validation.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...validation.warnings.map(
                  (warning) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(warning, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (profile != null) ...[
                _field('Full Name', profile.fullName),
                _field('Blood Group', profile.bloodGroup.isNotEmpty ? profile.bloodGroup : 'Unspecified'),
                _field('Demographics', '${profile.age} yrs  •  ${profile.gender}  •  ${profile.heightCm.toInt()} cm / ${profile.weightKg.toInt()} kg'),
                _field('Severe Allergies', profile.allergies.isNotEmpty ? profile.allergies.join(', ') : 'No Known Allergies (NKDA)'),
                _field('Current Medications', profile.medications.isNotEmpty ? profile.medications.join(', ') : 'None'),
                _field('Chronic Conditions', profile.chronicConditions.isNotEmpty ? profile.chronicConditions.join(', ') : 'None'),
                _field('Organ Donor Status', profile.organDonor ? 'Registered Donor ✓' : 'Not Registered'),
                _field('Insurance Details', '${profile.insuranceProvider ?? 'N/A'} (${profile.insuranceNumber ?? 'No policy'})'),
                _field('Primary Physician', '${profile.physicianName ?? 'N/A'} • ${profile.physicianPhone ?? ''}'),
                _field('Emergency Notes', profile.emergencyNotes.isNotEmpty ? profile.emergencyNotes : 'None provided'),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _field(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}
