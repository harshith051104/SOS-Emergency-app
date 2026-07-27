/// sos_circle_card.dart
///
/// Priority Emergency Responders Circle card backed by Riverpod SOSCircleController.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/features/emergency/sos_circle/presentation/providers/sos_circle_providers.dart';
import 'package:elly/features/emergency/sos_circle/domain/entities/emergency_contact.dart';

class SosCircleCard extends ConsumerWidget {
  const SosCircleCard({
    super.key,
    required this.isDark,
    required this.isActiveSos,
    required this.onViewAll,
  });

  final bool isDark;
  final bool isActiveSos;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final circleState = ref.watch(sosCircleControllerProvider);
    final List<EmergencyContact> contacts = circleState.contacts;



    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'SOS CIRCLE (${contacts.where((c) => c.isEnabled).length}/${contacts.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'Manage →',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: contacts.isEmpty
                ? const Center(
                    child: Text('No Emergency Contacts Configured', style: TextStyle(fontSize: 11, color: Colors.grey)))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return _buildAvatar(contact, isActiveSos);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(EmergencyContact contact, bool isActive) {
    final displayName = contact.fullName.split(' ').first;
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: contact.isPrimaryContact
                  ? AppColors.sosPrimary.withValues(alpha: 0.25)
                  : Colors.blue.withValues(alpha: 0.2),
              child: Text(
                contact.fullName.isNotEmpty ? contact.fullName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: contact.isPrimaryContact ? AppColors.sosPrimary : Colors.blue,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: contact.isEnabled
                      ? (isActive ? AppColors.successGreen : Colors.blue)
                      : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 54,
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: contact.isPrimaryContact ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
