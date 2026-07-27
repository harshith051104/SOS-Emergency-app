/// sos_circle_detail_sheet.dart
///
/// Emergency Contacts manager & escalation priority list modal sheet backed by Riverpod SOSCircleController.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/sos_circle/presentation/providers/sos_circle_providers.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/emergency_contact.dart';

class SosCircleDetailSheet extends ConsumerStatefulWidget {
  const SosCircleDetailSheet({super.key});

  @override
  ConsumerState<SosCircleDetailSheet> createState() => _SosCircleDetailSheetState();
}

class _SosCircleDetailSheetState extends ConsumerState<SosCircleDetailSheet> {
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isPrimary = false;

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showAddContactDialog(BuildContext context) {
    _nameController.clear();
    _relationController.clear();
    _phoneController.clear();
    _emailController.clear();
    _isPrimary = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Add Emergency Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Full Name *', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _relationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Relationship *', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Primary Phone *', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Email (Optional)', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Set as Primary Contact', style: TextStyle(color: Colors.white, fontSize: 13)),
                  value: _isPrimary,
                  activeTrackColor: AppColors.sosPrimary,
                  onChanged: (val) => setDialogState(() => _isPrimary = val),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.sosPrimary),
              onPressed: () async {
                final success = await ref.read(sosCircleControllerProvider.notifier).addContact(
                      fullName: _nameController.text.trim(),
                      relationship: _relationController.text.trim(),
                      primaryPhone: _phoneController.text.trim(),
                      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
                      isPrimaryContact: _isPrimary,
                    );
                if (success && ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final circleState = ref.watch(sosCircleControllerProvider);
    final List<EmergencyContact> contacts = circleState.contacts;


    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOS EMERGENCY CIRCLE',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.blue, letterSpacing: 0.8),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Trusted Emergency Contacts & Escalation List',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _showAddContactDialog(context),
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.blue),
                    tooltip: 'Add Contact',
                  ),
                ],
              ),
              if (circleState.validationError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          circleState.validationError!,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (contacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No emergency contacts added yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                )
              else
                ...contacts.map((contact) => _buildContactTile(context, ref, contact)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactTile(BuildContext context, WidgetRef ref, EmergencyContact contact) {
    final notifier = ref.read(sosCircleControllerProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: contact.isPrimaryContact ? AppColors.sosPrimary.withValues(alpha: 0.12) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: contact.isPrimaryContact ? AppColors.sosPrimary.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: contact.isPrimaryContact ? AppColors.sosPrimary : Colors.blue.shade700,
          child: Text(
            contact.fullName.isNotEmpty ? contact.fullName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
            ),
            if (contact.isPrimaryContact)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.sosPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('PRIMARY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${contact.relationship}  •  ${contact.primaryPhone}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
            if (contact.email != null && contact.email!.isNotEmpty)
              Text(
                contact.email!,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: contact.isEnabled,
              activeTrackColor: AppColors.successGreen,
              onChanged: (_) => notifier.toggleContactEnabled(contact.id),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 20),
              color: const Color(0xFF1E293B),
              onSelected: (val) {
                if (val == 'primary') {
                  notifier.setPrimaryContact(contact.id);
                } else if (val == 'delete') {
                  notifier.deleteContact(contact.id);
                }
              },
              itemBuilder: (ctx) => [
                if (!contact.isPrimaryContact)
                  const PopupMenuItem(
                    value: 'primary',
                    child: Text('Set as Primary', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Contact', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
