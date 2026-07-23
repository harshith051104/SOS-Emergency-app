/// add_edit_responder_page.dart
///
/// Form page for creating or editing an emergency responder.
/// If [responder] is null, operates in "add" mode.
/// If [responder] is provided (via GoRouter extras), operates in "edit" mode.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/responder.dart';
import '../../domain/enums/notification_method.dart';
import '../../domain/enums/responder_type.dart';
import '../providers/responder_providers.dart';
import '../widgets/notification_method_selector.dart';

/// Add or Edit a single emergency responder.
class AddEditResponderPage extends ConsumerStatefulWidget {
  const AddEditResponderPage({this.responder, super.key});

  /// Existing responder to edit, or null for "add new".
  final Responder? responder;

  @override
  ConsumerState<AddEditResponderPage> createState() =>
      _AddEditResponderPageState();
}

class _AddEditResponderPageState extends ConsumerState<AddEditResponderPage> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late ResponderType _selectedType;
  late List<NotificationMethod> _selectedMethods;
  late bool _isEnabled;
  bool _isSaving = false;

  bool get _isEditing => widget.responder != null;

  @override
  void initState() {
    super.initState();
    final r = widget.responder;
    _nameController = TextEditingController(text: r?.name ?? '');
    _phoneController = TextEditingController(text: r?.phoneNumber ?? '');
    _emailController = TextEditingController(text: r?.email ?? '');
    _selectedType = r?.type ?? ResponderType.family;
    _selectedMethods = List.from(
      r?.notificationMethods ??
          [NotificationMethod.pushNotification, NotificationMethod.sms],
    );
    _isEnabled = r?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Responder' : 'Add Responder'),
        centerTitle: false,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: const Text('Save'),
            ),
        ],
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Section: Identity ───────────────────────────────────────
            const _SectionHeader(label: 'Identity'),
            const SizedBox(height: 12),

            // Name field.
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                context,
                label: 'Name *',
                hint: 'e.g. Mom, Dr. Sharma',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),

            const SizedBox(height: 16),

            // Type dropdown.
            DropdownButtonFormField<ResponderType>(
              value: _selectedType,
              decoration: _inputDecoration(
                context,
                label: 'Responder Type *',
                icon: Icons.category_outlined,
              ),
              items: ResponderType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),

            const SizedBox(height: 28),

            // ── Section: Contact ────────────────────────────────────────
            const _SectionHeader(label: 'Contact Information'),
            const SizedBox(height: 12),

            // Phone field.
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                context,
                label: 'Phone Number',
                hint: '+91 98765 43210',
                icon: Icons.phone_outlined,
              ),
              validator: (v) {
                final needsPhone = _selectedMethods.any((m) => m.requiresPhone);
                if (needsPhone && (v == null || v.trim().isEmpty)) {
                  return 'Phone number required for SMS / Call';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email field.
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                context,
                label: 'Email (optional)',
                hint: 'contact@example.com',
                icon: Icons.email_outlined,
              ),
              validator: (v) {
                final needsEmail = _selectedMethods.any((m) => m.requiresEmail);
                if (needsEmail && (v == null || v.trim().isEmpty)) {
                  return 'Email required for Email notifications';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // ── Section: Notifications ──────────────────────────────────
            const _SectionHeader(label: 'Emergency Notifications'),
            const SizedBox(height: 12),

            NotificationMethodSelector(
              selectedMethods: _selectedMethods,
              onChanged: (methods) =>
                  setState(() => _selectedMethods = methods),
            ),

            const SizedBox(height: 28),

            // ── Section: Settings ───────────────────────────────────────
            const _SectionHeader(label: 'Settings'),
            const SizedBox(height: 8),

            SwitchListTile.adaptive(
              title: const Text('Enable Responder'),
              subtitle: Text(
                _isEnabled
                    ? 'This person will be notified during emergencies.'
                    : 'This person will be skipped during emergencies.',
              ),
              value: _isEnabled,
              onChanged: (v) => setState(() => _isEnabled = v),
              activeColor: AppColors.successGreen,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 40),

            // ── Save button ─────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.sosOnPrimary,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isEditing ? 'Save Changes' : 'Add Responder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sosPrimary,
                foregroundColor: AppColors.sosOnPrimary,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one notification method.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final responder = Responder(
      id: widget.responder?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      type: _selectedType,
      notificationMethods: _selectedMethods,
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      priority: widget.responder?.priority ?? 999,
      isEnabled: _isEnabled,
    );

    await ref
        .read(respondersControllerProvider.notifier)
        .saveResponder(responder);

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.4),
    );
  }
}

// ── Private Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppColors.sosPrimary,
      ),
    );
  }
}
