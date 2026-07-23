/// emergency_debug_page.dart
///
/// Hidden developer console visualizing real-time emergency telemetry,
/// contributor pipeline executions, local storage status, and debug logs.

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:elly/core/theme/app_colors.dart';
import 'package:elly/core/utils/app_logger.dart';
import '../../../sos/presentation/providers/emergency_providers.dart';
import '../providers/packet_providers.dart';
import '../../../assistant/presentation/providers/assistant_ui_providers.dart';

class EmergencyDebugPage extends ConsumerWidget {
  const EmergencyDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sosState = ref.watch(emergencyControllerProvider);
    final session = sosState.activeSession;

    // Watch packet state using session ID or fallback to empty string
    final packetState = ref.watch(packetControllerProvider(session?.sessionId ?? ''));
    final assistantState = ref.watch(assistantControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Emergency Debug Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(emergencyControllerProvider.notifier).resetToIdle(),
            tooltip: 'Force Reset SOS Status',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Session Overview ──
          _buildSectionHeader(context, 'Active SOS Session'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDebugRow('Status', sosState.status.name.toUpperCase(), isHighPriority: true),
                  _buildDebugRow('Session ID', session?.sessionId ?? 'None'),
                  _buildDebugRow('Duration', sosState.formattedDuration),
                  _buildDebugRow('Assistant Msg', sosState.assistantMessage),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Contributor Pipeline ──
          _buildSectionHeader(context, 'Contributor Pipeline Execution'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildContributorRow('1. EmergencyContributor', packetState.buildingProgress >= 1),
                  _buildContributorRow('2. DeviceContributor', packetState.buildingProgress >= 2),
                  _buildContributorRow('3. LocationContributor', packetState.buildingProgress >= 3),
                  _buildContributorRow('4. MedicalContributor', packetState.buildingProgress >= 4),
                  _buildContributorRow('5. ResponderContributor', packetState.buildingProgress >= 5),
                  _buildContributorRow('6. TimelineContributor', packetState.buildingProgress >= 6),
                  const Divider(height: 24),
                  _buildDebugRow('Checksum (FNV-1a)', packetState.packet?.metadata.checksum ?? 'Pending'),
                  _buildDebugRow('Estimated Size', packetState.packet?.metadata.packetSize ?? 'Pending'),
                  _buildDebugRow('Packet Version', packetState.packet?.version.toString() ?? 'Pending'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── GPS Telemetry ──
          _buildSectionHeader(context, 'GPS & Geocoding Telemetry'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDebugRow('Latitude', packetState.packet?.location.latitude?.toString() ?? 'Null / Unavailable'),
                  _buildDebugRow('Longitude', packetState.packet?.location.longitude?.toString() ?? 'Null / Unavailable'),
                  _buildDebugRow('Accuracy', packetState.packet?.location.accuracy ?? 'Unavailable'),
                  _buildDebugRow('Permissions', packetState.packet?.location.permissionStatus ?? 'Unknown'),
                  _buildDebugRow('GPS Enabled', (packetState.packet?.location.isGpsEnabled ?? false) ? 'YES' : 'NO'),
                  _buildDebugRow('Is Mocked GPS', (packetState.packet?.location.isMockLocation ?? false) ? 'YES' : 'NO'),
                  _buildDebugRow('Address', packetState.packet?.location.address ?? 'Unavailable'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── ELLY AI Live Assistant Diagnostics ──
          _buildSectionHeader(context, 'ELLY AI Live Assistant'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDebugRow('Status State', assistantState.state.name.toUpperCase(), isHighPriority: true),
                  _buildDebugRow('STT Latency', '${assistantState.metrics.sttLatencyMs} ms'),
                  _buildDebugRow('LLM Latency', '${assistantState.metrics.llmLatencyMs} ms'),
                  _buildDebugRow('TTS Latency', '${assistantState.metrics.ttsLatencyMs} ms'),
                  _buildDebugRow('Playback Latency', '${assistantState.metrics.playbackLatencyMs} ms'),
                  _buildDebugRow('End-to-End Latency', '${assistantState.metrics.endToEndLatencyMs} ms'),
                  _buildDebugRow('TTS Cache Hits', '${assistantState.metrics.ttsCacheHits} hits'),
                  _buildDebugRow('Conversation Count', '${assistantState.metrics.conversationCount}'),
                  _buildDebugRow('Safety Category', assistantState.metrics.safetyCategory.toUpperCase()),
                  _buildDebugRow('Last Transcript', assistantState.metrics.lastTranscript.isEmpty ? 'None' : assistantState.metrics.lastTranscript),
                  _buildDebugRow('Last Response', assistantState.metrics.lastResponse.isEmpty ? 'None' : assistantState.metrics.lastResponse),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Device & Hardware Diagnostics ──
          _buildSectionHeader(context, 'Device Hardware Telemetry'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDebugRow('Battery Level', packetState.packet != null ? '${packetState.packet!.device.batteryPercent}%' : 'Unknown'),
                  _buildDebugRow('Is Charging', packetState.packet != null ? (packetState.packet!.device.isCharging ? 'YES' : 'NO') : 'Unknown'),
                  _buildDebugRow('Battery Saver', packetState.packet != null ? (packetState.packet!.device.isBatterySaverEnabled ? 'ON' : 'OFF') : 'Unknown'),
                  _buildDebugRow('Connection Type', packetState.packet?.device.connectionType ?? 'Unknown'),
                  _buildDebugRow('Internet State', packetState.packet != null ? (packetState.packet!.device.isInternetAvailable ? 'CONNECTED' : 'OFFLINE') : 'Unknown'),
                  _buildDebugRow('Device Model', packetState.packet?.device.deviceName ?? 'Unknown'),
                  _buildDebugRow('OS Version', packetState.packet?.device.osVersion ?? 'Unknown'),
                  _buildDebugRow('Timezone', packetState.packet?.device.timeZone ?? 'Unknown'),
                  _buildDebugRow('Locale', packetState.packet?.device.locale ?? 'Unknown'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Developer Live Console Logs ──
          _buildSectionHeader(context, 'Live Application Logs'),
          Container(
            height: 350,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            padding: const EdgeInsets.all(12),
            child: const LogConsoleView(),
          ),
        ],
      ),
    );
  }

  // ── Builder Helpers ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.sosPrimary,
              letterSpacing: 1.0,
            ),
      ),
    );
  }

  Widget _buildDebugRow(String label, String value, {bool isHighPriority = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isHighPriority ? AppColors.sosPrimary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorRow(String name, bool isExecuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isExecuted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isExecuted ? AppColors.successGreen : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class LogConsoleView extends StatefulWidget {
  const LogConsoleView({super.key});

  @override
  State<LogConsoleView> createState() => _LogConsoleViewState();
}

class _LogConsoleViewState extends State<LogConsoleView> {
  late final List<TalkerData> _logs;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _logs = List<TalkerData>.from(appLogger.history);
    _subscription = appLogger.stream.listen((event) {
      if (mounted) {
        setState(() {
          _logs.add(event);
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reversedLogs = _logs.reversed.toList();
    if (reversedLogs.isEmpty) {
      return const Center(
        child: Text(
          'No logs recorded yet.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }
    return ListView.builder(
      itemCount: reversedLogs.length,
      itemBuilder: (context, index) {
        final item = reversedLogs[index];
        Color textColor = Colors.white70;
        if (item.title == 'error') textColor = Colors.redAccent;
        if (item.title == 'warning') textColor = Colors.orangeAccent;
        if (item.title == 'info') textColor = Colors.greenAccent;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '${item.title?.toUpperCase() ?? 'LOG'} | ${item.message}',
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }
}
