/// decision_console.dart
///
/// Developer diagnostics widget for monitoring Phase 6 Multi-Signal Decision Engine.
/// Displays recommendation badge, emergency confidence rating, explainability matrix,
/// evidence timeline, and rule trace execution logs.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/decision_recommendation.dart';
import '../../domain/entities/decision_state.dart';
import '../providers/decision_providers.dart';

class DecisionConsole extends ConsumerWidget {
  const DecisionConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decState = ref.watch(decisionControllerProvider);
    final telemetry = ref.watch(decisionTelemetryProvider);
    final config = ref.watch(decisionConfigProvider);
    final lastResult = decState.lastResult;
    final timeline = decState.evidenceTimeline;

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
                const Icon(Icons.psychology_rounded, color: Colors.purpleAccent, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Multi-Signal Decision Engine',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(decState.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(decState.status)),
                  ),
                  child: Text(
                    decState.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(decState.status),
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
            _buildInfoRow(
              'Reasoning Engine',
              lastResult != null
                  ? '${lastResult.engineVersion} (${lastResult.algorithmVersion})'
                  : 'RULE_BASED_ENGINE (v1.0.0-rules)',
            ),

            if (lastResult != null) ...[
              const SizedBox(height: 8),
              // Recommendation Badge Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getRecommendationColor(lastResult.recommendation).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _getRecommendationColor(lastResult.recommendation), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getRecommendationIcon(lastResult.recommendation),
                      color: _getRecommendationColor(lastResult.recommendation),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RECOMMENDATION: ${lastResult.recommendation.name.toUpperCase()}',
                      style: TextStyle(
                        color: _getRecommendationColor(lastResult.recommendation),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Emergency Confidence Progress Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Emergency Confidence:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  Text(
                    '${(lastResult.emergencyConfidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _getRecommendationColor(lastResult.recommendation),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: lastResult.emergencyConfidence,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getRecommendationColor(lastResult.recommendation),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),

              // Decision Reasons
              _buildSectionHeader('Decision Reasons'),
              for (final reason in lastResult.decisionReasons)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                      Expanded(
                        child: Text(reason, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),
              // Evidence Summary
              _buildSectionHeader('Evidence Matrix'),
              _buildInfoRow('Used', lastResult.evidenceUsed.isNotEmpty ? lastResult.evidenceUsed.join(', ') : 'None'),
              if (lastResult.evidenceIgnored.isNotEmpty)
                _buildInfoRow('Ignored', lastResult.evidenceIgnored.join(', '), highlightColor: Colors.orangeAccent),
              if (lastResult.missingEvidence.isNotEmpty)
                _buildInfoRow('Missing', lastResult.missingEvidence.join(', '), highlightColor: Colors.amberAccent),
              if (lastResult.expiredEvidence.isNotEmpty)
                _buildInfoRow('Expired', lastResult.expiredEvidence.join(', '), highlightColor: Colors.redAccent),

              const SizedBox(height: 8),
              _buildInfoRow('Processing Latency', '${lastResult.processingTimeMs} ms'),
              _buildInfoRow('Session ID', lastResult.sessionId),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Awaiting multi-modal evidence signals for emergency evaluation...',
                  style: TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            // Evidence Timeline Section
            if (timeline.isNotEmpty) ...[
              const Divider(color: Colors.white10, height: 20),
              _buildSectionHeader('Evidence Signal Timeline'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in timeline.reversed.take(6))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          entry,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Evaluations: ${telemetry.evaluationCount} | Failures: ${telemetry.failureCount}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Max Latency Target: ${config.maxLatencyMs}ms',
                  style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
            width: 130,
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

  Color _getStatusColor(DecisionStatus status) {
    switch (status) {
      case DecisionStatus.idle:
        return Colors.grey;
      case DecisionStatus.evaluating:
        return Colors.purpleAccent;
      case DecisionStatus.completed:
        return Colors.green;
      case DecisionStatus.failed:
        return Colors.redAccent;
    }
  }

  Color _getRecommendationColor(DecisionRecommendation rec) {
    switch (rec) {
      case DecisionRecommendation.normal:
        return Colors.green;
      case DecisionRecommendation.monitor:
        return Colors.cyanAccent;
      case DecisionRecommendation.requestConfirmation:
        return Colors.amberAccent;
      case DecisionRecommendation.highRisk:
        return Colors.redAccent;
    }
  }

  IconData _getRecommendationIcon(DecisionRecommendation rec) {
    switch (rec) {
      case DecisionRecommendation.normal:
        return Icons.check_circle_outline_rounded;
      case DecisionRecommendation.monitor:
        return Icons.visibility_rounded;
      case DecisionRecommendation.requestConfirmation:
        return Icons.warning_amber_rounded;
      case DecisionRecommendation.highRisk:
        return Icons.dangerous_rounded;
    }
  }
}
