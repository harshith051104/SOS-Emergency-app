/// sos_flow_detail_sheet.dart
///
/// Interactive 6-Step Circular Workflow Modal Sheet for "What Happens During SOS".
/// Features:
///   - 6-Node Circular Workflow with animated clockwise arrows
///   - Automatic step carousel with pause-on-touch interaction
///   - Dynamic active detail card with status indicator & progress bar
///   - Dot pagination and primary "Got It ✓" dismissal button

library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Representation of each step in the 6-step SOS response workflow.
class _SosStepData {
  const _SosStepData({
    required this.number,
    required this.title,
    required this.subLabel,
    required this.fullTitle,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.bgColor,
  });

  final int number;
  final String title;
  final String subLabel;
  final String fullTitle;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color bgColor;
}

const List<_SosStepData> _kSosSteps = [
  _SosStepData(
    number: 1,
    title: 'Detect',
    subLabel: 'Emergency\nDetected',
    fullTitle: 'Detect — Emergency Detected',
    description:
        'Instant activation via manual trigger, voice wake-word ("Help me"), or AI sensor detection (falls, crash, abnormal vitals).',
    icon: Icons.notifications_active_rounded,
    primaryColor: Color(0xFFFF2E4D),
    bgColor: Color(0xFFFFE5EA),
  ),
  _SosStepData(
    number: 2,
    title: 'Alert',
    subLabel: 'Notify SOS\nCircle',
    fullTitle: 'Alert — Notify SOS Circle',
    description:
        'Immediate SMS, push notification, and automated voice call sent to your prioritized emergency contact circle.',
    icon: Icons.send_rounded,
    primaryColor: Color(0xFF9333EA),
    bgColor: Color(0xFFF3E8FF),
  ),
  _SosStepData(
    number: 3,
    title: 'Dispatch',
    subLabel: 'Ambulance &\nServices',
    fullTitle: 'Dispatch — Ambulance & Emergency Services',
    description:
        'Direct routing to regional emergency services (112 / 911 / 999 / 000 based on live GPS location).',
    icon: Icons.add_box_rounded,
    primaryColor: Color(0xFF0284C7),
    bgColor: Color(0xFFE0F2FE),
  ),
  _SosStepData(
    number: 4,
    title: 'Inform',
    subLabel: 'Hospital &\nAuthorities',
    fullTitle: 'Inform — Hospital & Local Authorities',
    description:
        'Real-time encrypted telemetry transmission to nearest regional hospital ERs and first responder hubs.',
    icon: Icons.apartment_rounded,
    primaryColor: Color(0xFF0D9488),
    bgColor: Color(0xFFCCFBF1),
  ),
  _SosStepData(
    number: 5,
    title: 'Share',
    subLabel: 'Live Location &\nHealth Data',
    fullTitle: 'Share — Live Location & Health Data',
    description:
        'Encrypted 5-second interval GPS location tracking link and Emergency Health Passport shared with active responders.',
    icon: Icons.location_on_rounded,
    primaryColor: Color(0xFF16A34A),
    bgColor: Color(0xFFDCFCE7),
  ),
  _SosStepData(
    number: 6,
    title: 'Assist',
    subLabel: 'Live ELLY Voice\nGuidance',
    fullTitle: 'Assist — Live ELLY Voice Guidance',
    description:
        '24/7 AI Guardian providing calm voice guidance, CPR / first-aid steps, and live session monitoring until safe.',
    icon: Icons.headset_mic_rounded,
    primaryColor: Color(0xFFE11D48),
    bgColor: Color(0xFFFFE4E6),
  ),
];

class SosFlowDetailSheet extends StatefulWidget {
  const SosFlowDetailSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SosFlowDetailSheet(),
    );
  }

  @override
  State<SosFlowDetailSheet> createState() => _SosFlowDetailSheetState();
}

class _SosFlowDetailSheetState extends State<SosFlowDetailSheet> {
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  Timer? _userPauseTimer;
  bool _isUserPaused = false;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _userPauseTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted || _isUserPaused) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _kSosSteps.length;
      });
    });
  }

  void _onSelectStep(int index) {
    setState(() {
      _currentIndex = index;
      _isUserPaused = true;
    });

    // Pause autoplay for 6 seconds after user interaction, then resume
    _userPauseTimer?.cancel();
    _userPauseTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _isUserPaused = false;
        });
      }
    });
  }

  void _nextStep() {
    _onSelectStep((_currentIndex + 1) % _kSosSteps.length);
  }

  void _previousStep() {
    _onSelectStep((_currentIndex - 1 + _kSosSteps.length) % _kSosSteps.length);
  }

  @override
  Widget build(BuildContext context) {
    final activeStep = _kSosSteps[_currentIndex];
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Top Drag Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Top Header Row (Title + Close Button)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What Happens During SOS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '6-Step Automated Emergency Response & Dispatch Pipeline',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          // Scrollable Body (Circular Workflow + Active Detail Card)
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < 0) {
                  _nextStep();
                } else if ((details.primaryVelocity ?? 0) > 0) {
                  _previousStep();
                }
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ── 1. Circular Workflow Diagram ──────────────────────────
                    SizedBox(
                      height: 330,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final centerX = constraints.maxWidth / 2;
                          final centerY = 150.0;
                          final radius = math.min(centerX - 55, 125.0);

                          return Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Circular Ring & Connecting Clockwise Arrows
                              CustomPaint(
                                size: Size(constraints.maxWidth, 300),
                                painter: _CircularWorkflowPainter(
                                  centerX: centerX,
                                  centerY: centerY,
                                  radius: radius,
                                  activeIndex: _currentIndex,
                                  activeColor: activeStep.primaryColor,
                                ),
                              ),

                              // 6 Node Badges
                              ...List.generate(_kSosSteps.length, (index) {
                                final step = _kSosSteps[index];
                                final isSelected = index == _currentIndex;

                                // Angle calculation (-90° starts at top center)
                                final angle = -math.pi / 2 + (index * 2 * math.pi / 6);
                                final nodeX = centerX + radius * math.cos(angle);
                                final nodeY = centerY + radius * math.sin(angle);

                                return Positioned(
                                  left: nodeX - 45,
                                  top: nodeY - 32,
                                  child: GestureDetector(
                                    onTap: () => _onSelectStep(index),
                                    behavior: HitTestBehavior.opaque,
                                    child: AnimatedScale(
                                      scale: isSelected ? 1.12 : 0.92,
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOutBack,
                                      child: AnimatedOpacity(
                                        opacity: isSelected ? 1.0 : 0.72,
                                        duration: const Duration(milliseconds: 250),
                                        child: SizedBox(
                                          width: 90,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Circle Icon + Number Badge
                                              Stack(
                                                clipBehavior: Clip.none,
                                                alignment: Alignment.center,
                                                children: [
                                                  // Icon Container with Glow
                                                  AnimatedContainer(
                                                    duration: const Duration(milliseconds: 250),
                                                    width: 48,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      color: step.bgColor,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? step.primaryColor
                                                            : step.primaryColor.withValues(alpha: 0.35),
                                                        width: isSelected ? 2.5 : 1.5,
                                                      ),
                                                      boxShadow: isSelected
                                                          ? [
                                                              BoxShadow(
                                                                color: step.primaryColor.withValues(alpha: 0.35),
                                                                blurRadius: 12,
                                                                spreadRadius: 2,
                                                              ),
                                                            ]
                                                          : [],
                                                    ),
                                                    child: Icon(
                                                      step.icon,
                                                      color: step.primaryColor,
                                                      size: 22,
                                                    ),
                                                  ),

                                                  // Number Badge Tag
                                                  Positioned(
                                                    left: -2,
                                                    top: -2,
                                                    child: Container(
                                                      width: 18,
                                                      height: 18,
                                                      decoration: BoxDecoration(
                                                        color: step.primaryColor,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(color: Colors.white, width: 1.5),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${step.number}',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w900,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),

                                              // Title Label
                                              Text(
                                                step.title,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                                  color: isSelected ? step.primaryColor : const Color(0xFF1E293B),
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                              ),

                                              // Sub-label Text
                                              Text(
                                                step.subLabel,
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF64748B),
                                                  height: 1.1,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── 2. Active Step Detail Card ────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey<int>(_currentIndex),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: activeStep.bgColor.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: activeStep.primaryColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Icon Badge Circle
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: activeStep.primaryColor.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: activeStep.primaryColor.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    activeStep.icon,
                                    color: activeStep.primaryColor,
                                    size: 26,
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: activeStep.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${activeStep.number}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Middle Info Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeStep.fullTitle,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    activeStep.description,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF475569),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Live Status Line
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: activeStep.primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'In Progress...',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: activeStep.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Step Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: (_currentIndex + 1) / _kSosSteps.length,
                                      backgroundColor: Colors.black.withValues(alpha: 0.08),
                                      valueColor: AlwaysStoppedAnimation<Color>(activeStep.primaryColor),
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Right Action Arrow
                            GestureDetector(
                              onTap: _nextStep,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: activeStep.primaryColor,
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 3. Dot Page Indicators ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_kSosSteps.length, (index) {
                        final isSelected = index == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isSelected ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeStep.primaryColor
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    // ── 4. Primary Dismissal Button ───────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Got It',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.check_rounded, size: 20, weight: 3.0),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter drawing the outer circle ring & clockwise directional arrows connecting nodes.
class _CircularWorkflowPainter extends CustomPainter {
  _CircularWorkflowPainter({
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.activeIndex,
    required this.activeColor,
  });

  final double centerX;
  final double centerY;
  final double radius;
  final int activeIndex;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw main circular ring
    canvas.drawCircle(Offset(centerX, centerY), radius, ringPaint);

    // Active arc highlight
    final activeArcPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2 + ((activeIndex - 1) * 2 * math.pi / 6);
    const sweepAngle = 2 * math.pi / 6;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      startAngle,
      sweepAngle,
      false,
      activeArcPaint,
    );

    // Draw 6 clockwise directional arrows between nodes
    final arrowPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final isSegmentActive = i == activeIndex;
      arrowPaint.color = isSegmentActive ? activeColor : const Color(0xFF94A3B8);

      // Angle of midpoint between node i and node i+1
      final midAngle = -math.pi / 2 + (i * 2 * math.pi / 6) + (math.pi / 6);
      final arrowX = centerX + radius * math.cos(midAngle);
      final arrowY = centerY + radius * math.sin(midAngle);

      // Tangent angle pointing clockwise
      final tangentAngle = midAngle + math.pi / 2;

      canvas.save();
      canvas.translate(arrowX, arrowY);
      canvas.rotate(tangentAngle);

      // Draw arrowhead triangle
      final path = Path()
        ..moveTo(5, 0)
        ..lineTo(-4, -4)
        ..lineTo(-2, 0)
        ..lineTo(-4, 4)
        ..close();

      canvas.drawPath(path, arrowPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CircularWorkflowPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex || oldDelegate.activeColor != activeColor;
  }
}
