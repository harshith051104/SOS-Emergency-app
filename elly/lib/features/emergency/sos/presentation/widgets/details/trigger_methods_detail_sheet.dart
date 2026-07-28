/// trigger_methods_detail_sheet.dart
///
/// Production-ready SOS Trigger Configuration System Modal Sheet.
/// Features Riverpod state management, local persistence, permission checks,
/// and clear user guidance for all 4 supported emergency trigger methods.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elly/core/theme/app_colors.dart';
import '../../../domain/entities/sos_trigger_config.dart';
import '../../providers/sos_trigger_config_provider.dart';


class TriggerMethodsDetailSheet extends ConsumerWidget {
  const TriggerMethodsDetailSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(sosTriggerConfigProvider);
    final notifier = ref.read(sosTriggerConfigProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 14),


              // ── 3. Wake Word ──────────────────────────────────────────────
              _buildTriggerCard(
                context: context,
                isDark: isDark,
                icon: Icons.record_voice_over_rounded,
                iconColor: Colors.purpleAccent,
                name: '3. Wake Word ("Hey Elly SOS")',
                description: 'Acoustic voice command activation: "Hey Elly SOS".',
                isEnabled: config.isWakeWordEnabled,
                onChanged: (val) => notifier.toggleWakeWord(val),
                permissionWidget: _buildPermissionChip(
                  context,
                  ref,
                  'Microphone',
                  config.microphonePermission,
                ),
              ),
              const SizedBox(height: 14),

              // ── 4. Automatic Detection ────────────────────────────────────
              _buildTriggerCard(
                context: context,
                isDark: isDark,
                icon: Icons.sensors_rounded,
                iconColor: Colors.orangeAccent,
                name: '4. Automatic Detection',
                description: 'Impact, Fall & Accelerometer automatic trigger.',
                isEnabled: config.isAutoDetectionEnabled,
                onChanged: (val) => notifier.toggleAutoDetection(val),
                futureSensorsWidget: const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _SensorChip(label: 'Motion'),
                      _SensorChip(label: 'Accelerometer'),
                      _SensorChip(label: 'Gyroscope'),
                      _SensorChip(label: 'Fall Detection'),
                      _SensorChip(label: 'Health Signals'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Informational Footer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.blue.shade900 : Colors.blue.shade50).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All trigger settings are saved locally and survive app & device restarts.',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    ),
  );
}




  Widget _buildTriggerCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String name,
    required String description,
    String? badgeText,
    Color? badgeColor,
    required bool isEnabled,
    bool isLocked = false,
    required ValueChanged<bool>? onChanged,
    String? reasonIfLocked,
    Widget? permissionWidget,
    Widget? futureSensorsWidget,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnabled
              ? iconColor.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? Colors.blue).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: badgeColor ?? Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: isLocked ? null : onChanged,
                activeThumbColor: iconColor,
              ),
            ],
          ),
          if (reasonIfLocked != null) ...[
            const SizedBox(height: 8),
            Text(
              '• $reasonIfLocked',
              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
          if (permissionWidget != null) permissionWidget,
          if (futureSensorsWidget != null) futureSensorsWidget,
        ],
      ),
    );
  }

  Widget _buildPermissionChip(
    BuildContext context,
    WidgetRef ref,
    String permName,
    TriggerPermissionStatus status,
  ) {
    final isGranted = status == TriggerPermissionStatus.granted;
    final color = isGranted ? Colors.green : Colors.amber;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isGranted ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                '$permName Permission: ${isGranted ? "Granted" : "Missing / Denied"}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          if (!isGranted)
            GestureDetector(
              onTap: () => ref.read(sosTriggerConfigProvider.notifier).openSystemSettings(),
              child: const Text(
                'Open Settings →',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }
}

class _SensorChip extends StatelessWidget {
  const _SensorChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
      ),
    );
  }
}
