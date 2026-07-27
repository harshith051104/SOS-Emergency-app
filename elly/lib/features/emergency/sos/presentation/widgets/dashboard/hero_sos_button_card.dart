/// hero_sos_button_card.dart
///
/// Circular Hero SOS button widget with pulse animation.

library;

import 'package:flutter/material.dart';
import 'package:elly/core/theme/app_colors.dart';

class HeroSosButtonCard extends StatefulWidget {
  const HeroSosButtonCard({
    super.key,
    required this.isLocked,
    required this.isActive,
    required this.onTap,
  });

  final bool isLocked;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<HeroSosButtonCard> createState() => _HeroSosButtonCardState();
}

class _HeroSosButtonCardState extends State<HeroSosButtonCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isActive ? AppColors.sosPrimary : const Color(0xFFE11D48);

    return Column(
      children: [
        const SizedBox(height: 12),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isActive ? _pulseAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: widget.isLocked ? null : widget.onTap,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.45),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sos_rounded,
                            size: 54,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.isActive ? 'SOS ACTIVE' : 'TAP FOR SOS',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),
        Text(
          widget.isActive ? 'Waiting for responder acknowledgement...' : 'Tap for Emergency  •  Press & Hold',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
      ],
    );
  }
}
