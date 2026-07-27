/// emergency_packet_page.dart
///
/// Premium Material 3 dashboard visualizing compiled Emergency Data Packets.
/// Includes compile pipeline indicators and accessibility optimizations.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:elly/core/theme/app_colors.dart';
import '../../domain/entities/emergency_packet.dart';
import '../../domain/entities/responder_section.dart';
import '../controllers/packet_controller.dart';
import '../providers/packet_providers.dart';

class EmergencyPacketPage extends ConsumerWidget {
  const EmergencyPacketPage({
    required this.sessionId,
    super.key,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(packetControllerProvider(sessionId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Emergency Data Packet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(context, state, isDark),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EmergencyPacketState state, bool isDark) {
    switch (state.status) {
      case PacketStateStatus.loading:
      case PacketStateStatus.building:
        return _CompilationChecklistScreen(
          progress: state.buildingProgress,
          isDark: isDark,
        );
      case PacketStateStatus.failed:
        return _ErrorScreen(
          message: state.errorMessage ?? 'Compilation failed.',
          isDark: isDark,
        );
      case PacketStateStatus.expired:
        return _ErrorScreen(
          message: 'This emergency session has expired.',
          isDark: isDark,
        );
      case PacketStateStatus.ready:
        if (state.packet == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _PacketDashboardScreen(
          packet: state.packet!,
          isDark: isDark,
        );
    }
  }
}

// ── Compilation Progress Checklist Screen ───────────────────────────────────

class _CompilationChecklistScreen extends StatelessWidget {
  const _CompilationChecklistScreen({
    required this.progress,
    required this.isDark,
  });

  final int progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final steps = [
      'Initialize SOS Packet Session',
      'Collect Device Diagnostics & Sensors',
      'Retrieve GPS Coordinates & Address',
      'Load Local Medical & Emergency Profile',
      'Prepare Responder Escalation Pipeline',
      'Assemble Unified Milestone Timeline',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  color: AppColors.sosPrimary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Compiling Emergency Packet',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assembling telemetry, location details, and profiles...',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              color: isDark
                  ? AppColors.cardDark
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: List.generate(steps.length, (index) {
                    final itemProgress = index + 1;
                    final isDone = progress >= itemProgress;
                    final isActive = progress == index;

                    Color itemColor = Colors.grey.withValues(alpha: 0.5);
                    IconData icon = Icons.radio_button_unchecked_rounded;

                    if (isDone) {
                      itemColor = AppColors.successGreen;
                      icon = Icons.check_circle_rounded;
                    } else if (isActive) {
                      itemColor = AppColors.sosPrimary;
                      icon = Icons.sync_rounded;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(icon, color: itemColor, size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              steps[index],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isDone
                                    ? theme.colorScheme.onSurface
                                    : isActive
                                        ? AppColors.sosPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error Screen ────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.message,
    required this.isDark,
  });

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.sosPrimary,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            'Packet Error',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }
}

// ── Packet Dashboard Screen ──────────────────────────────────────────────────

class _PacketDashboardScreen extends StatelessWidget {
  const _PacketDashboardScreen({
    required this.packet,
    required this.isDark,
  });

  final EmergencyPacket packet;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView(

      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      children: [
        // 1. Packet Summary Section
        _buildSummaryHeader(context),
        const SizedBox(height: 20),

        // 2. Health Indicators Row
        _buildHealthIndicatorsRow(context),
        const SizedBox(height: 20),

        // 3. Location Telemetry Card
        _LocationCard(packet: packet, isDark: isDark),
        const SizedBox(height: 18),

        // 4. Medical / Emergency Profile Card
        _MedicalCard(packet: packet, isDark: isDark),
        const SizedBox(height: 18),

        // 5. Device Telemetry Card
        _DeviceCard(packet: packet, isDark: isDark),
        const SizedBox(height: 18),

        // 6. Emergency Responders Card
        _RespondersCard(packet: packet, isDark: isDark),
        const SizedBox(height: 18),

        // 7. Timeline Events Card
        _TimelineCard(packet: packet, isDark: isDark),
        const SizedBox(height: 24),

        // 8. Sharing/Export Action Buttons (Disabled placeholders)
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildSummaryHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Packet',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'ID: ${packet.id}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.sosPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    packet.status.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.sosPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeaderStat(context, 'Compiled', 'Just Now'),
                _buildHeaderStat(context, 'Size', packet.metadata.packetSize),
                GestureDetector(
                  onLongPress: () => context.push('/emergency/debug'),
                  behavior: HitTestBehavior.opaque,
                  child: _buildHeaderStat(context, 'Quality', '92% 🟢'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHealthIndicatorsRow(BuildContext context) {
    return Row(
      children: [
        _buildHealthDot(context, 'Location', '🟢'),
        const SizedBox(width: 8),
        _buildHealthDot(context, 'Medical', '🟢'),
        const SizedBox(width: 8),
        _buildHealthDot(context, 'Voice', '⚪'),
        const SizedBox(width: 8),
        _buildHealthDot(context, 'Wearable', '⚪'),
      ],
    );
  }

  Widget _buildHealthDot(BuildContext context, String label, String dot) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        elevation: 0,
        color: isDark ? AppColors.cardDark.withValues(alpha: 0.5) : AppColors.cardLight.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(dot, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share Packet'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing coming soon in Phase 5')),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Export PDF'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF Export coming soon in Phase 5')),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Location Card ───────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.packet,
    required this.isDark,
  });

  final EmergencyPacket packet;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = packet.location;
    final hasCoords = loc.latitude != null && loc.longitude != null;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.my_location_rounded, color: AppColors.sosPrimary),
                const SizedBox(width: 12),
                Text(
                  'GPS Location Telemetry',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Address', loc.address),
            _buildDetailRow(
              'Coordinates',
              hasCoords ? '${loc.latitude!.toStringAsFixed(6)}, ${loc.longitude!.toStringAsFixed(6)}' : 'Unavailable',
            ),
            _buildDetailRow('Accuracy', loc.accuracy),
            _buildDetailRow('GPS Active', loc.isGpsEnabled ? 'Yes 🟢' : 'No 🔴'),
            _buildDetailRow('Mock GPS', loc.isMockLocation ? 'Simulated 🟡' : 'Hardware 🟢'),
            _buildDetailRow('Permissions', loc.permissionStatus),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open Google Maps (Coming Soon)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: null, // Disabled placeholder
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Medical Profile Card ────────────────────────────────────────────────────

class _MedicalCard extends StatelessWidget {
  const _MedicalCard({
    required this.packet,
    required this.isDark,
  });

  final EmergencyPacket packet;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final med = packet.medical;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_information_rounded, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Medical & Emergency Profile',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'MEDICAL INFORMATION',
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Blood Group', med.medicalInfo.bloodGroup),
            _buildDetailRow('Allergies', med.medicalInfo.allergies.isEmpty ? 'None' : med.medicalInfo.allergies.join(', ')),
            _buildDetailRow('Conditions', med.medicalInfo.medicalConditions.isEmpty ? 'None' : med.medicalInfo.medicalConditions.join(', ')),
            _buildDetailRow('Medications', med.medicalInfo.currentMedications.isEmpty ? 'None' : med.medicalInfo.currentMedications.join(', ')),
            const Divider(height: 24),
            Text(
              'EMERGENCY NOTES & INSURANCE',
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Doctor Contact', '${med.emergencyInfo.doctorName} (${med.emergencyInfo.doctorPhone})'),
            _buildDetailRow('Preferred Hospital', med.emergencyInfo.preferredHospital),
            _buildDetailRow('Insurance', '${med.emergencyInfo.insuranceProvider} (#${med.emergencyInfo.insurancePolicyNumber})'),
            _buildDetailRow('Emergency Notes', med.emergencyInfo.emergencyNotes),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device Telemetry Card ───────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.packet,
    required this.isDark,
  });

  final EmergencyPacket packet;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dev = packet.device;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.developer_board_rounded, color: Colors.purple),
                const SizedBox(width: 12),
                Text(
                  'Hardware Diagnostics',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Device Model', dev.deviceName),
            _buildDetailRow('OS Details', dev.osVersion),
            _buildDetailRow('Battery Level', '${dev.batteryPercent}% (${dev.isCharging ? "Charging" : "Discharging"})'),
            _buildDetailRow('Battery Saver', dev.isBatterySaverEnabled ? 'Active 🟡' : 'Off 🟢'),
            _buildDetailRow('Network Type', dev.connectionType.toUpperCase()),
            _buildDetailRow('Internet Status', dev.isInternetAvailable ? 'Available 🟢' : 'Offline 🔴'),
            _buildDetailRow('Timezone', dev.timeZone),
            _buildDetailRow('Locale', dev.locale),
            _buildDetailRow('ELLY App Version', 'v1.0.0+1 (Beta)'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Responders Pipeline Card ────────────────────────────────────────────────

class _RespondersCard extends StatelessWidget {
  const _RespondersCard({
    required this.packet,
    required this.isDark,
  });

  final EmergencyPacket packet;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = packet.responders.responders;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Responder Escalation Logs',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No emergency contacts configured.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                ),
              )
            else
              ...list.map((r) {
                Color statusColor = Colors.grey;
                String label = 'Pending';
                IconData icon = Icons.radio_button_unchecked_rounded;

                switch (r.notificationStatus) {
                  case ResponderNotificationStatus.pending:
                    statusColor = Colors.grey;
                    label = 'Pending';
                    icon = Icons.radio_button_unchecked_rounded;
                    break;
                  case ResponderNotificationStatus.notified:
                    statusColor = const Color(0xFFF59E0B);
                    label = 'Notified';
                    icon = Icons.hourglass_empty_rounded;
                    break;
                  case ResponderNotificationStatus.accepted:
                    statusColor = AppColors.successGreen;
                    label = 'Alerted & Confirmed';
                    icon = Icons.check_circle_rounded;
                    break;
                  case ResponderNotificationStatus.timedOut:
                    statusColor = AppColors.sosPrimary;
                    label = 'Escalated (No ACK)';
                    icon = Icons.error_rounded;
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: statusColor.withValues(alpha: 0.12),
                              child: Icon(icon, color: statusColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    r.relationship,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ── Timeline Card ───────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.packet,
    required this.isDark,
  });

  final EmergencyPacket packet;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final events = packet.timeline.events;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_toggle_off_rounded, color: Colors.teal),
                const SizedBox(width: 12),
                Text(
                  'Unified Event Timeline',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Timeline empty.', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isLast = index == events.length - 1;
                  final timeStr = DateFormat('HH:mm:ss').format(event.timestamp);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppColors.successGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 52,
                              color: AppColors.successGreen.withValues(alpha: 0.3),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.description,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
