/// confirmation_console.dart
///
/// Developer diagnostics widget for monitoring Phase 7 Confirmation Engine status,
/// active strategy countdowns, voice/button user interaction triggers, session lifecycle, and telemetry.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/confirmation_outcome.dart';
import '../../domain/entities/confirmation_method.dart';
import '../../domain/entities/confirmation_state.dart';
import '../../domain/entities/interruption_reason.dart';
import '../providers/confirmation_providers.dart';

class ConfirmationConsole extends ConsumerWidget {
  const ConfirmationConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confState = ref.watch(confirmationControllerProvider);
    final telemetry = ref.watch(confirmationTelemetryProvider);
    final lastResult = confState.lastResult;
    final strategy = confState.activeStrategy;
    final isWaiting = confState.status == ConfirmationStatus.waiting;

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
                const Icon(Icons.touch_app_rounded, color: Colors.orangeAccent, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Confirmation Engine',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(confState.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(confState.status)),
                  ),
                  child: Text(
                    confState.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(confState.status),
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
            _buildInfoRow('Session Lifecycle', confState.sessionLifecycleState.name.toUpperCase(), highlightColor: Colors.amberAccent),
            _buildInfoRow('Active Strategy', '${strategy.name} (Timeout: ${strategy.timeout.inSeconds}s)'),
            _buildInfoRow('Capabilities', 'Voice: ${strategy.allowVoice ? "YES" : "NO"} | Buttons: ${strategy.allowButtons ? "YES" : "NO"}'),

            if (isWaiting) ...[
              const SizedBox(height: 10),
              // Live Countdown Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Countdown Timer (${strategy.name}):',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${confState.remainingSeconds}s remaining',
                    style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strategy.timeout.inSeconds > 0 ? confState.remainingSeconds / strategy.timeout.inSeconds : 0.0,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),

              // Interactive Developer Test Response Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ref.read(confirmationControllerProvider.notifier).confirmUserResponse(
                              method: ConfirmationMethod.button,
                              text: 'CONFIRM EMERGENCY BUTTON PRESSED',
                            );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text('🖐️ CONFIRM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ref.read(confirmationControllerProvider.notifier).cancelConfirmation();
                      },
                      icon: const Icon(Icons.cancel_rounded, size: 16),
                      label: const Text('🛑 CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],

            if (lastResult != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getOutcomeColor(lastResult.confirmationOutcome).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _getOutcomeColor(lastResult.confirmationOutcome), width: 1.5),
                ),
                child: Text(
                  'OUTCOME: ${lastResult.confirmationOutcome.name.toUpperCase()} (Via ${lastResult.confirmationMethod.name.toUpperCase()})',
                  style: TextStyle(
                    color: _getOutcomeColor(lastResult.confirmationOutcome),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (lastResult.userResponse != null)
                _buildInfoRow('User Response Text', lastResult.userResponse!),
              if (lastResult.interruptionReason != InterruptionReason.none)
                _buildInfoRow('Interruption Reason', lastResult.interruptionReason.name, highlightColor: Colors.purpleAccent),
              _buildInfoRow('Response Time', '${lastResult.responseTimeMs} ms'),
              _buildInfoRow('Session ID', lastResult.sessionId),
            ] else if (!isWaiting) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Awaiting decision recommendation for confirmation strategy activation...',
                  style: TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Conf: ${telemetry.confirmationCount} | Timeout: ${telemetry.timeoutCount} | Cancel: ${telemetry.cancellationCount} | Interrupt: ${telemetry.interruptedCount}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                Text(
                  'Rate: ${telemetry.confirmationRate.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
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

  Color _getStatusColor(ConfirmationStatus status) {
    switch (status) {
      case ConfirmationStatus.idle:
        return Colors.grey;
      case ConfirmationStatus.waiting:
        return Colors.amberAccent;
      case ConfirmationStatus.confirmed:
        return Colors.green;
      case ConfirmationStatus.cancelled:
        return Colors.redAccent;
      case ConfirmationStatus.timedOut:
        return Colors.orangeAccent;
      case ConfirmationStatus.interrupted:
        return Colors.purpleAccent;
      case ConfirmationStatus.completed:
        return Colors.cyanAccent;
      case ConfirmationStatus.failed:
        return Colors.red;
    }
  }

  Color _getOutcomeColor(ConfirmationOutcome outcome) {
    switch (outcome) {
      case ConfirmationOutcome.confirmed:
        return Colors.green;
      case ConfirmationOutcome.cancelled:
        return Colors.redAccent;
      case ConfirmationOutcome.timedOut:
        return Colors.orangeAccent;
      case ConfirmationOutcome.interrupted:
        return Colors.purpleAccent;
      case ConfirmationOutcome.noConfirmationRequired:
        return Colors.cyanAccent;
    }
  }
}
