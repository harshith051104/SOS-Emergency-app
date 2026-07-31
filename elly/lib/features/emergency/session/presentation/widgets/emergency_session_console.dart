/// emergency_session_console.dart
///
/// Developer diagnostics widget for monitoring Phase 8 Emergency Session Activation,
/// action execution chips, acknowledgement tracking, execution timeline, and telemetry.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../domain/entities/emergency_session_state.dart';
import '../../domain/entities/acknowledgement_status.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_outcome.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_result.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/confirmation_method.dart';
import 'package:elly/features/emergency/confirmation/domain/entities/session_lifecycle_state.dart';
import '../providers/session_providers.dart';

class EmergencySessionConsole extends ConsumerWidget {
  const EmergencySessionConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(activeEmergencySessionControllerProvider);
    final telemetry = ref.watch(emergencyExecutionTelemetryProvider);
    final lastResult = sessionState.lastResult;
    final isExecuting = sessionState.status == EmergencySessionStatus.executing;

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Emergency Session (Phase 8)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(sessionState.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(sessionState.status)),
                  ),
                  child: Text(
                    sessionState.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(sessionState.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Execution Action Chips
            const Text('Configured Emergency Actions:', style: TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildActionChip('SMS', lastResult?.successfulActions.contains('send_sms') ?? false, isExecuting),
                _buildActionChip('Phone Call', lastResult?.successfulActions.contains('phone_call') ?? false, isExecuting),
                _buildActionChip('GPS Share', lastResult?.successfulActions.contains('location_sharing') ?? false, isExecuting),
                _buildActionChip('Medical Profile', lastResult?.successfulActions.contains('medical_profile') ?? false, isExecuting),
                _buildActionChip('Timeline', lastResult?.successfulActions.contains('emergency_timeline') ?? false, isExecuting),
                _buildActionChip('Notification', lastResult?.successfulActions.contains('emergency_notification') ?? false, isExecuting),
              ],
            ),
            const SizedBox(height: 12),

            if (lastResult != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getAckColor(lastResult.acknowledgementStatus).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _getAckColor(lastResult.acknowledgementStatus), width: 1.5),
                ),
                child: Text(
                  'ACKNOWLEDGEMENT: ${lastResult.acknowledgementStatus.name.toUpperCase()} (State: ${lastResult.sessionState.name.toUpperCase()})',
                  style: TextStyle(
                    color: _getAckColor(lastResult.acknowledgementStatus),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Execution Duration', '${lastResult.executionDurationMs} ms'),
              _buildInfoRow('Actions Executed', '${lastResult.successfulActions.length} / ${lastResult.executedActions.length} successful'),
              _buildInfoRow('Session ID', lastResult.sessionId),
            ] else if (!isExecuting) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Awaiting Phase 7 confirmation result for automatic emergency session activation...',
                  style: TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            if (sessionState.executionTimeline.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Execution Timeline:', style: TextStyle(color: Colors.white60, fontSize: 11)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sessionState.executionTimeline.length,
                  itemBuilder: (context, index) {
                    final item = sessionState.executionTimeline[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(
                        item,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),
            // Developer manual test execution buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isExecuting
                        ? null
                        : () {
                            final confResult = ConfirmationResult(
                              sessionId: 'manual_session_${DateTime.now().millisecondsSinceEpoch}',
                              confirmationOutcome: ConfirmationOutcome.confirmed,
                              sessionLifecycleState: SessionLifecycleState.confirmed,
                              confirmationMethod: ConfirmationMethod.button,
                              responseTimeMs: 200,
                              userResponse: 'MANUAL TEST TRIGGER',
                              timestamp: DateTime.now(),
                            );
                            ref.read(activeEmergencySessionControllerProvider.notifier).startSession(
                                  sessionId: confResult.sessionId,
                                  confirmationResult: confResult,
                                  emergencyConfidence: 0.98,
                                  confirmationOutcome: ConfirmationOutcome.confirmed,
                                  decisionReasons: const ['Manual Developer Trigger'],
                                );
                          },
                    icon: const Icon(Icons.flash_on_rounded, size: 16),
                    label: const Text('🚀 TEST SESSION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      ref.read(activeEmergencySessionControllerProvider.notifier).cancelSession();
                    },
                    icon: const Icon(Icons.stop_rounded, size: 16),
                    label: const Text('🛑 CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              ],
            ),

            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Started: ${telemetry.sessionsStarted} | Completed: ${telemetry.sessionsCompleted} | Cancelled: ${telemetry.sessionsCancelled}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                Text(
                  'Avg: ${telemetry.averageExecutionTimeMs.toStringAsFixed(0)}ms',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, bool isSuccess, bool isExecuting) {
    final color = isSuccess
        ? Colors.green
        : (isExecuting ? Colors.amber : Colors.grey.shade700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : (isExecuting ? Icons.hourglass_top : Icons.circle_outlined),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlightColor ?? Colors.white,
                fontSize: 11,
                fontWeight: highlightColor != null ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(EmergencySessionStatus status) {
    switch (status) {
      case EmergencySessionStatus.idle:
        return Colors.grey;
      case EmergencySessionStatus.starting:
        return Colors.amberAccent;
      case EmergencySessionStatus.executing:
        return Colors.orangeAccent;
      case EmergencySessionStatus.waitingAcknowledgement:
        return Colors.cyanAccent;
      case EmergencySessionStatus.completed:
        return Colors.green;
      case EmergencySessionStatus.failed:
        return Colors.red;
      case EmergencySessionStatus.cancelled:
        return Colors.purpleAccent;
    }
  }

  Color _getAckColor(AcknowledgementStatus ack) {
    switch (ack) {
      case AcknowledgementStatus.delivered:
        return Colors.cyanAccent;
      case AcknowledgementStatus.acknowledged:
        return Colors.green;
      case AcknowledgementStatus.failed:
        return Colors.red;
      case AcknowledgementStatus.timedOut:
        return Colors.orangeAccent;
      case AcknowledgementStatus.unknown:
        return Colors.grey;
    }
  }
}
