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
import 'package:elly/features/emergency/voice_trigger/presentation/widgets/wake_word_management_sheet.dart';


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

                // Sheet Header Title
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HOW SOS IS TRIGGERED',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.sosPrimary : const Color(0xFFFF2E4D),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Configure manual, voice & AI automated triggers',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── 1. Manual SOS Trigger (Mandatory & Locked) ───────────────
                _buildTriggerCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.touch_app_rounded,
                  iconColor: const Color(0xFFFF2E4D),
                  name: '1. Manual SOS Trigger',
                  description: 'Press big SOS button, side-button triple-click, or shake device to trigger emergency.',
                  badgeText: 'MANDATORY',
                  badgeColor: const Color(0xFFFF2E4D),
                  isEnabled: true,
                  isLocked: true,
                  reasonIfLocked: 'Manual trigger is mandatory for core emergency safety.',
                  onChanged: null,
                ),
                const SizedBox(height: 12),

                // ── 2. Voice Wake-Word SOS ────────────────────────────────────
                _buildTriggerCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.mic_rounded,
                  iconColor: const Color(0xFF9333EA),
                  name: '2. Voice Wake-Word SOS',
                  description: 'Continuously listens for phrases like "Help me", "Emergency", "I can\'t breathe", or custom wake words.',
                  isEnabled: config.isVoiceTriggerEnabled,
                  onChanged: (val) {
                    notifier.toggleVoiceTrigger(val);
                    if (val) {
                      WakeWordManagementSheet.show(context);
                    }
                  },
                  permissionWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPermissionChip(
                        context,
                        ref,
                        'Microphone',
                        config.microphonePermission,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => WakeWordManagementSheet.show(context),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Edit & Add Custom Wake Words'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3E8FF),
                          foregroundColor: const Color(0xFF9333EA),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFD8B4FE)),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── 3. AI Sensor Auto-Detection (Coming Soon) ────────────────
                _buildTriggerCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.sensors_rounded,
                  iconColor: const Color(0xFFD97706),
                  name: '3. AI Sensor Auto-Detection',
                  description: 'Uses accelerometer & gyroscope to detect sudden falls, high-impact crashes, or sudden immobility.',
                  badgeText: 'COMING SOON',
                  badgeColor: const Color(0xFFD97706),
                  isEnabled: false,
                  isLocked: true,
                  reasonIfLocked: 'AI distress and fall detection is coming soon in an upcoming update.',
                  onChanged: null,
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
                const SizedBox(height: 20),



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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: isEnabled
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        if (badgeText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? Colors.blue).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: (badgeColor ?? Colors.blue).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: badgeColor ?? Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (isEnabled) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ] else ...[
                      const SizedBox(height: 2),
                      const Text(
                        'Feature disabled. Toggle switch to activate.',
                        style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
                      ),
                    ],
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
          if (isEnabled && reasonIfLocked != null) ...[
            const SizedBox(height: 8),
            Text(
              '• $reasonIfLocked',
              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
          if (isEnabled && permissionWidget != null) permissionWidget,
          if (isEnabled && futureSensorsWidget != null) futureSensorsWidget,
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
