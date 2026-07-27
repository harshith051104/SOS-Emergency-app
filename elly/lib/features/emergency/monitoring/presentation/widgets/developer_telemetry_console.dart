/// developer_telemetry_console.dart
///
/// Comprehensive Developer Telemetry Dashboard displaying real-time flight recorder logs,
/// sensor health matrices, confidence & severity ratings, FNV-1a checksums, and live reactive packet streams.

library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/monitoring_config.dart';
import '../../domain/entities/packet_record.dart';
import '../../domain/entities/timeline_entry.dart';
import '../../domain/entities/emergency_severity.dart';
import '../providers/monitoring_provider.dart';
import 'package:elly/features/emergency/reliability/presentation/providers/reliability_provider.dart';
import 'package:elly/features/emergency/communication/presentation/providers/communication_provider.dart';
import 'package:elly/features/emergency/communication/domain/entities/communication_request.dart';
import 'package:elly/features/emergency/communication/data/transports/internet_transport.dart';
import 'package:elly/features/emergency/communication/data/transports/sms_transport.dart';
import 'package:elly/features/emergency/packet/presentation/widgets/emergency_data_packet_card.dart';
import 'package:elly/features/emergency/packet/presentation/widgets/packet_scheduler_status_card.dart';
import 'package:elly/features/emergency/offline/presentation/widgets/offline_status_card.dart';
import 'package:elly/features/emergency/global/presentation/widgets/cross_border_status_card.dart';
import 'package:elly/features/emergency/offline_resilience/presentation/widgets/offline_resilience_status_card.dart';
import 'package:elly/features/emergency/readiness/presentation/widgets/readiness_status_card.dart';
import 'package:elly/features/emergency/communication/presentation/widgets/communication_status_card.dart';



class DeveloperTelemetryConsole extends ConsumerStatefulWidget {
  const DeveloperTelemetryConsole({
    super.key,
    this.sessionId,
  });

  final String? sessionId;

  @override
  ConsumerState<DeveloperTelemetryConsole> createState() => _DeveloperTelemetryConsoleState();
}

class _DeveloperTelemetryConsoleState extends ConsumerState<DeveloperTelemetryConsole>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _expandedPacketIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final engineStateAsync = ref.watch(monitoringEngineStateProvider);
    final engineState = engineStateAsync.value ?? ref.read(monitoringRepositoryProvider).currentState;
    final metrics = ref.watch(monitoringMetricsProvider);
    final timeline = ref.watch(timelineEventsProvider);

    final packetStreamAsync = ref.watch(packetStreamProvider);
    final currentPacket = packetStreamAsync.value;

    final isEngineRunning = engineState.isRunning;

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      child: Column(
        children: [
          // ── Console Header ──────────────────────────────────────────
          _ConsoleHeader(
            statusName: engineState.status.name.toUpperCase(),
            sessionId: engineState.sessionId ?? widget.sessionId ?? 'N/A',
            isDark: isDark,
          ),

          // ── Metrics & Health Dashboard ──────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Real-time Metrics Card
                _MetricsGridCard(metrics: metrics, isDark: isDark),
                const SizedBox(height: 12),

                // Confidence & Severity Matrix
                if (currentPacket != null) ...[
                  _ConfidenceAndSeverityCard(
                    packet: currentPacket,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Controls (Start Live Session / Force Snapshot / Stop)
                _ActionControlsBar(
                  isRunning: isEngineRunning,
                  onStartDevSession: () => _startDevSession(ref),
                  onForceCycle: () => _triggerForceCycle(ref),
                  onStopSession: () => _stopDevSession(ref),
                ),
                const SizedBox(height: 16),

                // ── Live Engine Debug Status Cards ─────────────────────────
                EmergencyDataPacketCard(isDark: isDark),
                const SizedBox(height: 12),
                PacketSchedulerStatusCard(isDark: isDark),
                const SizedBox(height: 12),
                OfflineStatusCard(isDark: isDark),
                const SizedBox(height: 12),
                CrossBorderStatusCard(isDark: isDark),
                const SizedBox(height: 12),
                OfflineResilienceStatusCard(isDark: isDark),
                const SizedBox(height: 12),
                ReadinessStatusCard(isDark: isDark),
                const SizedBox(height: 12),
                CommunicationStatusCard(isDark: isDark),
                const SizedBox(height: 16),



                // Tab Bar for Packets vs Timeline vs Reliability vs Communication
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.amber.shade700,
                  labelColor: Colors.amber.shade700,
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  tabs: const [
                    Tab(text: 'PACKETS 📦'),
                    Tab(text: 'TIMELINE 📜'),
                    Tab(text: 'RELIABILITY 🛡️'),
                    Tab(text: 'COMM 📡'),
                  ],
                ),
                const SizedBox(height: 12),

                // Tab Content Height Box
                SizedBox(
                  height: 380,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Live Packet Stream
                      _PacketStreamView(
                        expandedIndex: _expandedPacketIndex,
                        onToggleExpand: (idx) {
                          setState(() {
                            _expandedPacketIndex = _expandedPacketIndex == idx ? null : idx;
                          });
                        },
                        sessionId: engineState.sessionId ?? widget.sessionId,
                        latestPacket: currentPacket,
                        isDark: isDark,
                      ),

                      // Tab 2: Timeline Logs
                      _TimelineLogView(
                        entries: timeline,
                        isDark: isDark,
                      ),

                      // Tab 3: Reliability & Offline Survival Engine Dashboard
                      _ReliabilityDashboardView(
                        isDark: isDark,
                        sessionId: engineState.sessionId ?? widget.sessionId,
                      ),

                      // Tab 4: Communication Gateway & Transport Dashboard
                      _CommunicationDashboardView(
                        isDark: isDark,
                        sessionId: engineState.sessionId ?? widget.sessionId,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDevSession(WidgetRef ref) async {
    final startUseCase = ref.read(startMonitoringUseCaseProvider);
    final devSessionId = 'DEV_SESSION_${DateTime.now().millisecondsSinceEpoch}';

    await startUseCase.execute(
      sessionId: devSessionId,
      triggerType: 'dev_console_manual',
      config: const MonitoringConfig(
        normalInterval: Duration(seconds: 4),
        criticalInterval: Duration(seconds: 3),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚀 Live Dev Monitoring Started ($devSessionId)!'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.shade800,
        ),
      );
    }
  }

  Future<void> _stopDevSession(WidgetRef ref) async {
    final stopUseCase = ref.read(stopMonitoringUseCaseProvider);
    await stopUseCase.execute();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛑 Live Dev Monitoring Stopped.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  Future<void> _triggerForceCycle(WidgetRef ref) async {
    final repo = ref.read(monitoringRepositoryProvider);
    final packet = await repo.forceTelemetryCycle(reasonCode: 'dev_forced_snapshot');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚡ Snapshot #${packet?.packetNumber ?? 1} Forced! Hash: ${packet?.checksum ?? 'N/A'}'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.amber.shade700,
        ),
      );
    }
  }
}

// ── Private Console Sub-Widgets ──────────────────────────────────────────────

class _ConsoleHeader extends StatelessWidget {
  const _ConsoleHeader({
    required this.statusName,
    required this.sessionId,
    required this.isDark,
  });

  final String statusName;
  final String sessionId;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'FLIGHT RECORDER ENGINE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.0,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusName == 'ACTIVE' ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: statusName == 'ACTIVE' ? Colors.green : Colors.grey,
              ),
            ),
            child: Text(
              'STATUS: $statusName',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusName == 'ACTIVE' ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGridCard extends StatelessWidget {
  const _MetricsGridCard({
    required this.metrics,
    required this.isDark,
  });

  final dynamic metrics;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LIVE ENGINE METRICS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricTile('Packets', '${metrics.packetsGenerated}', Icons.dataset_rounded, isDark),
                _buildMetricTile('Avg Time', '${metrics.averageCollectionTimeMs.toStringAsFixed(1)}ms', Icons.timer_rounded, isDark),
                _buildMetricTile('Rate', '${metrics.packetGenerationRatePerMin.toStringAsFixed(1)}/m', Icons.speed_rounded, isDark),
                _buildMetricTile('GPS Acc', metrics.lastGpsAccuracy, Icons.gps_fixed_rounded, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.amber),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceAndSeverityCard extends StatelessWidget {
  const _ConfidenceAndSeverityCard({
    required this.packet,
    required this.isDark,
  });

  final PacketRecord packet;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final conf = packet.telemetry.confidence;
    final sev = packet.telemetry.severity;

    Color sevColor = Colors.green;
    if (sev.level == EmergencySeverityLevel.critical) {
      sevColor = Colors.red;
    } else if (sev.level == EmergencySeverityLevel.high) {
      sevColor = Colors.orange;
    } else if (sev.level == EmergencySeverityLevel.medium) {
      sevColor = Colors.amber;
    }

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONFIDENCE: ${conf.overallConfidence}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sevColor),
                  ),
                  child: Text(
                    'SEVERITY: ${sev.level.name.toUpperCase()} (${sev.score})',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sevColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Confidence Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: conf.overallConfidence / 100.0,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  conf.overallConfidence > 80 ? Colors.green : Colors.amber,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),

            // Component confidence breakdown
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildBadge('Loc', '${conf.locationConfidence}%'),
                _buildBadge('Net', '${conf.networkConfidence}%'),
                _buildBadge('Mot', '${conf.motionConfidence}%'),
                _buildBadge('Bat', '${conf.batteryConfidence}%'),
                _buildBadge('Hlth', '${conf.healthConfidence}%'),
              ],
            ),

            const SizedBox(height: 6),
            Text(
              'Reason: ${packet.reasonCode}  •  Hash: ${packet.checksum}',
              style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String key, String val) {
    return Text(
      '$key: $val',
      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
    );
  }
}

class _ActionControlsBar extends StatelessWidget {
  const _ActionControlsBar({
    required this.isRunning,
    required this.onStartDevSession,
    required this.onForceCycle,
    required this.onStopSession,
  });

  final bool isRunning;
  final VoidCallback onStartDevSession;
  final VoidCallback onForceCycle;
  final VoidCallback onStopSession;

  @override
  Widget build(BuildContext context) {
    if (!isRunning) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: const Text('START LIVE MONITORING SESSION 🚀'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
        ),
        onPressed: onStartDevSession,
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text('FORCE SNAPSHOT ⚡'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            onPressed: onForceCycle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.stop_rounded, size: 16, color: Colors.redAccent),
            label: const Text('STOP 🛑', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: onStopSession,
          ),
        ),
      ],
    );
  }
}

class _PacketStreamView extends ConsumerWidget {
  const _PacketStreamView({
    required this.expandedIndex,
    required this.onToggleExpand,
    required this.sessionId,
    required this.latestPacket,
    required this.isDark,
  });

  final int? expandedIndex;
  final ValueChanged<int> onToggleExpand;
  final String? sessionId;
  final PacketRecord? latestPacket;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessionId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline_rounded, size: 36, color: Colors.amber),
            const SizedBox(height: 8),
            const Text(
              'No active emergency session.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "START LIVE MONITORING SESSION" above to launch real-time telemetry testing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final storage = ref.watch(monitoringStorageServiceProvider);

    return FutureBuilder<List<PacketRecord>>(
      future: storage.getPackets(sessionId!),
      builder: (context, snapshot) {
        final packets = snapshot.data ?? [];
        if (packets.isEmpty && latestPacket == null) {
          return const Center(child: Text('Waiting for initial packet stream generation...'));
        }

        // Include latest packet if not in list yet
        if (latestPacket != null && !packets.any((p) => p.packetNumber == latestPacket!.packetNumber)) {
          packets.add(latestPacket!);
        }

        final reversed = packets.reversed.toList();

        return ListView.builder(
          itemCount: reversed.length,
          itemBuilder: (context, index) {
            final packet = reversed[index];

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: ExpansionTile(
                key: Key('packet_${packet.sessionId}_${packet.packetNumber}'),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.amber.withValues(alpha: 0.2),
                  child: Text(
                    '#${packet.packetNumber}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ),
                title: Text(
                  'Packet #${packet.packetNumber} — ${packet.reasonCode}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Checksum: ${packet.checksum}  •  ${packet.localTime.toIso8601String().substring(11, 19)}',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        _prettyJsonPacket(packet),
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.greenAccent),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _prettyJsonPacket(PacketRecord p) {
    final map = {
      'schemaVersion': p.schemaVersion,
      'packetNumber': p.packetNumber,
      'reasonCode': p.reasonCode,
      'sessionId': p.sessionId,
      'utcTime': p.utcTime.toIso8601String(),
      'localTime': p.localTime.toIso8601String(),
      'monotonicElapsedMs': p.monotonicElapsedMs,
      'checksum': p.checksum,
      'location': {
        'lat': p.telemetry.location.latitude,
        'lng': p.telemetry.location.longitude,
        'accuracy': p.telemetry.location.accuracy,
        'address': p.telemetry.location.address,
      },
      'device': {
        'battery': '${p.telemetry.device.batteryPercent}%',
        'charging': p.telemetry.device.isCharging,
        'platform': p.telemetry.device.platform,
      },
      'connectivity': {
        'connection': p.telemetry.connectivity.connectionType,
        'internet': p.telemetry.connectivity.isInternetAvailable,
      },
      'confidence': {
        'overall': '${p.telemetry.confidence.overallConfidence}%',
      },
      'severity': {
        'level': p.telemetry.severity.level.name.toUpperCase(),
        'score': p.telemetry.severity.score,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(map);
  }
}

class _TimelineLogView extends StatelessWidget {
  const _TimelineLogView({
    required this.entries,
    required this.isDark,
  });

  final List<TimelineEntry> entries;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No timeline event logs recorded yet.'));
    }

    final reversed = entries.reversed.toList();

    return ListView.builder(
      itemCount: reversed.length,
      itemBuilder: (context, index) {
        final entry = reversed[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 6),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.event_note_rounded, size: 18, color: Colors.amber),
            title: Text(
              entry.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${entry.description}\n${entry.localTime.toIso8601String().substring(11, 19)}  •  Category: ${entry.category}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

class _ReliabilityDashboardView extends ConsumerWidget {
  const _ReliabilityDashboardView({
    required this.isDark,
    this.sessionId,
  });

  final bool isDark;
  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relStateAsync = ref.watch(reliabilityStateStreamProvider);
    final relState = relStateAsync.value ?? ref.read(reliabilityRepositoryProvider).currentState;
    final connStateAsync = ref.watch(connectivityStateStreamProvider);
    final connState = connStateAsync.value ?? ref.read(offlineSurvivalEngineProvider).connectivityMonitor.currentState;
    final capabilityAsync = ref.watch(networkCapabilityStreamProvider);
    final capability = capabilityAsync.value ?? ref.read(offlineSurvivalEngineProvider).qualityMonitor.currentCapabilities;
    final syncStatusAsync = ref.watch(syncStatusStreamProvider);
    final syncStatus = syncStatusAsync.value ?? ref.read(offlineSurvivalEngineProvider).syncEngine.currentSyncStatus;
    final score = ref.watch(reliabilityScoreProvider);

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        // Overall Reliability Score & Mode Card
        Card(
          elevation: 0,
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENGINE STATE: ${relState.status.name.toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: relState.isOfflineMode ? Colors.amber : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connectivity: ${connState.overallStatus.name.toUpperCase()} (Internet: ${connState.isInternetAvailable})',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${score.overallScore}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.amber),
                      ),
                      const Text('RELIABILITY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Network Capabilities Card
        Card(
          elevation: 0,
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NETWORK CAPABILITY MATRIX', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _chip('HTTP', capability.canHttp),
                    _chip('DNS', capability.canDns),
                    _chip('TCP', capability.canTcp),
                    _chip('UDP', capability.canUdp),
                    _chip('Captive Portal', !capability.isCaptivePortal),
                    _chip('SMS Fallback', capability.canSmsFallback),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Queue & Sync Status Card
        Card(
          elevation: 0,
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PENDING QUEUE: ${syncStatus.pendingCount} ITEMS', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('SYNCING: ${syncStatus.isSynchronizing}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Synced: ${syncStatus.syncedCount}  •  Failed: ${syncStatus.failedCount}  •  Backoff: ${syncStatus.currentBackoffDelayMs}ms',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Simulation Test Controls
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.wifi_off_rounded, size: 14),
              label: const Text('SIMULATE NETWORK DROP 📵', style: TextStyle(fontSize: 10)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white),
              onPressed: () {
                final engine = ref.read(offlineSurvivalEngineProvider);
                engine.enqueuePacket(payloadJson: '{"test":"offline_drop_payload"}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📵 Network Drop & Offline Queueing Triggered!')),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync_rounded, size: 14),
              label: const Text('TRIGGER QUEUE SYNC 🔄', style: TextStyle(fontSize: 10)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
              onPressed: () {
                if (sessionId != null) {
                  ref.read(synchronizeQueueUseCaseProvider).execute(sessionId: sessionId!);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: active ? Colors.green : Colors.red),
      ),
      child: Text(
        '$label: ${active ? "✓" : "✗"}',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: active ? Colors.green : Colors.red),
      ),
    );
  }
}

class _CommunicationDashboardView extends ConsumerWidget {
  const _CommunicationDashboardView({
    required this.isDark,
    this.sessionId,
  });

  final bool isDark;
  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commStateAsync = ref.watch(communicationStateStreamProvider);
    final commState = commStateAsync.value ?? ref.read(communicationRepositoryProvider).currentState;
    final trackerAsync = ref.watch(deliveryTrackerStreamProvider);
    final trackerStatus = trackerAsync.value;
    final healthMatrixAsync = ref.watch(transportHealthMatrixProvider);
    final healthMatrix = healthMatrixAsync.value ?? {};

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        // Active Status & Transport Card
        Card(
          elevation: 0,
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMM GATEWAY: ${commState.status.name.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Active Transport: ${commState.activeTransport ?? 'INTERNET (Default)'}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text('DISPATCH READY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Transport Health Matrix Card
        Card(
          elevation: 0,
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TRANSPORT HEALTH MATRIX', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _healthBadge('Internet', healthMatrix['internet']?.isOperational ?? true),
                    _healthBadge('SMS', healthMatrix['sms']?.isOperational ?? true),
                    _healthBadge('Phone', healthMatrix['phone']?.isOperational ?? true),
                    _healthBadge('Email', healthMatrix['email']?.isOperational ?? true),
                    _healthBadge('Bluetooth', healthMatrix['bluetooth']?.isOperational ?? false),
                    _healthBadge('Mesh', healthMatrix['mesh']?.isOperational ?? false),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Delivery Tracker Status Card
        if (trackerStatus != null) ...[
          Card(
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RECEIPT: ${trackerStatus.state.name.toUpperCase()} (${trackerStatus.transportUsed})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  const SizedBox(height: 4),
                  Text(
                    'Request: ${trackerStatus.requestId}  •  RTT: ${trackerStatus.roundTripTimeMs}ms',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Interactive Simulation Controls
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 14),
              label: const Text('DISPATCH VIA INTERNET 🌐', style: TextStyle(fontSize: 10)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade800, foregroundColor: Colors.white),
              onPressed: () async {
                final manager = ref.read(communicationManagerServiceProvider);
                manager.injectTransportOverride('internet', InternetTransport());
                await ref.read(sendEmergencyCommunicationUseCaseProvider).execute(
                  CommunicationRequest(
                    requestId: 'req_${DateTime.now().millisecondsSinceEpoch}',
                    sessionId: sessionId ?? 'DEV_SESS',
                    payloadJson: '{"test":"internet_dispatch"}',
                    priority: 'critical',
                    guaranteeLevel: 'mustDeliver',
                    recipientTargets: const ['+18005550199'],
                    createdAt: DateTime.now(),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.sms_failed_rounded, size: 14),
              label: const Text('FAIL INTERNET ❌ ➔ SMS 💬', style: TextStyle(fontSize: 10)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900, foregroundColor: Colors.white),
              onPressed: () async {
                final manager = ref.read(communicationManagerServiceProvider);
                manager.injectTransportOverride('internet', InternetTransport(forceFailure: true));
                manager.injectTransportOverride('sms', SmsTransport());
                await ref.read(sendEmergencyCommunicationUseCaseProvider).execute(
                  CommunicationRequest(
                    requestId: 'req_esc_${DateTime.now().millisecondsSinceEpoch}',
                    sessionId: sessionId ?? 'DEV_SESS',
                    payloadJson: '{"test":"sms_escalation_dispatch"}',
                    priority: 'critical',
                    guaranteeLevel: 'mustDeliver',
                    recipientTargets: const ['+18005550199'],
                    createdAt: DateTime.now(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _healthBadge(String name, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ok ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ok ? Colors.green : Colors.grey),
      ),
      child: Text(
        '$name: ${ok ? "✓" : "✗"}',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: ok ? Colors.green : Colors.grey),
      ),
    );
  }
}
