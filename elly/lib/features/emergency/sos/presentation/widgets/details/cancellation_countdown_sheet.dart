/// cancellation_countdown_sheet.dart
///
/// 3-second haptic countdown cancellation sheet for false alarm handling.

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:elly/core/theme/app_colors.dart';

class CancellationCountdownSheet extends StatefulWidget {
  const CancellationCountdownSheet({
    super.key,
    required this.onConfirmProceed,
    required this.onCancelSos,
  });

  final VoidCallback onConfirmProceed;
  final VoidCallback onCancelSos;

  @override
  State<CancellationCountdownSheet> createState() => _CancellationCountdownSheetState();
}

class _CancellationCountdownSheetState extends State<CancellationCountdownSheet> {
  int _secondsRemaining = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        widget.onConfirmProceed();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text(
            'ACTIVATING EMERGENCY IN $_secondsRemaining',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.sosPrimary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap CANCEL below if triggered accidentally.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.cancel_rounded, size: 20),
            label: const Text('CANCEL SOS 🛑'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            onPressed: () {
              _timer?.cancel();
              widget.onCancelSos();
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              widget.onConfirmProceed();
            },
            child: const Text('SEND NOW ⚡', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
