/// emergency_service_selection_page.dart
///
/// Dedicated Emergency Service Category Selection Page (Sprint 4.1).
/// Enforces single-selection validation, 10-second automatic fallback selection
/// to Universal Helpline (112), and transitions workflow to Preparing Emergency Dispatch.

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/router/app_router.dart';
import '../../domain/entities/emergency_service_model.dart';
import '../providers/emergency_service_provider.dart';
import '../controllers/emergency_session_controller.dart';

class EmergencyServiceSelectionPage extends ConsumerStatefulWidget {
  const EmergencyServiceSelectionPage({super.key});

  @override
  ConsumerState<EmergencyServiceSelectionPage> createState() => _EmergencyServiceSelectionPageState();
}

class _EmergencyServiceSelectionPageState extends ConsumerState<EmergencyServiceSelectionPage> {
  Timer? _autoSelectTimer;
  int _autoSelectSeconds = 10;

  @override
  void initState() {
    super.initState();
    _startAutoSelectCountdown();
  }

  void _startAutoSelectCountdown() {
    _autoSelectTimer?.cancel();
    _autoSelectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_autoSelectSeconds > 1) {
        setState(() => _autoSelectSeconds--);
      } else {
        timer.cancel();
        _handleAutoFallback();
      }
    });
  }

  void _handleAutoFallback() {
    final serviceState = ref.read(emergencyServiceProvider);
    final universal = serviceState.services.firstWhere(
      (s) => s.id == 'srv_universal',
      orElse: () => const EmergencyService(
        id: 'srv_universal',
        name: 'Universal Helpline',
        description: 'National Unified Emergency Response Standard',
        emergencyNumber: '112',
        icon: Icons.emergency_rounded,
        category: 'universal',
        priority: 6,
      ),
    );

    ref.read(emergencySessionControllerProvider.notifier).completeServiceSelection(universal);
    ref.read(emergencySessionControllerProvider.notifier).startDispatchPreparing();

    if (mounted) {
      context.go(AppRoutes.emergencyGenerating);
    }
  }

  void _handleUserContinue(EmergencyService selected) {
    _autoSelectTimer?.cancel();
    ref.read(emergencySessionControllerProvider.notifier).completeServiceSelection(selected);
    ref.read(emergencySessionControllerProvider.notifier).startDispatchPreparing();
    context.go(AppRoutes.emergencyGenerating);
  }

  @override
  void dispose() {
    _autoSelectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(emergencyServiceProvider);
    final serviceNotifier = ref.read(emergencyServiceProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selected = serviceState.selectedService;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text(
          'SELECT EMERGENCY SERVICE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _autoSelectTimer?.cancel();
            ref.read(emergencySessionControllerProvider.notifier).resetToIdle();
            context.go(AppRoutes.home);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto-Selection Timer Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AUTO-SELECTING UNIVERSAL (112) IN ${_autoSelectSeconds}s',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Instructions Header
              Text(
                'Direct Emergency Helpline Dispatch',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Select which emergency department should respond to your situation:',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 14),

              // 6 Service Cards List
              Expanded(
                child: serviceState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: serviceState.services.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final service = serviceState.services[index];
                          final isSelected = selected == service;

                          return _EmergencyServiceCard(
                            service: service,
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () {
                              serviceNotifier.selectService(service);
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),

              // Selected Service Summary Banner
              if (selected != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sosPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sosPrimary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(selected.icon, color: AppColors.sosPrimary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Selected: ${selected.name} (${selected.emergencyNumber})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sosPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),

              // Continue Button
              ElevatedButton.icon(
                onPressed: selected == null ? null : () => _handleUserContinue(selected),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(
                  selected == null ? 'SELECT A SERVICE TO CONTINUE' : 'CONTINUE TO DISPATCH',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColors.sosPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
                  disabledForegroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: selected == null ? 0 : 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyServiceCard extends StatelessWidget {
  const _EmergencyServiceCard({
    required this.service,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final EmergencyService service;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sosPrimary.withValues(alpha: 0.14)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.sosPrimary : theme.colorScheme.outline.withValues(alpha: 0.12),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Service Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.sosPrimary.withValues(alpha: 0.2)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                service.icon,
                color: isSelected ? AppColors.sosPrimary : theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Name & Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? AppColors.sosPrimary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.description,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Number Badge & Selection Check Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.sosPrimary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    service.emergencyNumber,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? AppColors.sosPrimary : Colors.grey.shade400,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
