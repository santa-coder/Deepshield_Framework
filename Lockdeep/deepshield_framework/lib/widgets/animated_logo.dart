// lib/widgets/animated_logo.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AnimatedLogo extends StatefulWidget {
  final double size;
  const AnimatedLogo({super.key, this.size = 100});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this, duration: const Duration(seconds: 8))..repeat();
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _rotateAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _rotateAnim]),
      builder: (context, _) {
        return SizedBox(
          width: widget.size, height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: _rotateAnim.value * 6.2832,
                child: Container(
                  width: widget.size, height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.3), width: 1),
                    gradient: SweepGradient(colors: [
                      AppTheme.neonBlue.withValues(alpha: 0.8),
                      Colors.transparent,
                      AppTheme.neonBlue.withValues(alpha: 0.1),
                    ]),
                  ),
                ),
              ),
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: widget.size * 0.75, height: widget.size * 0.75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [BoxShadow(color: AppTheme.neonBlue.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)],
                  ),
                ),
              ),
              Container(
                width: widget.size * 0.5, height: widget.size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surface,
                  boxShadow: [BoxShadow(color: AppTheme.neonBlue.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 4)],
                ),
                child: Icon(Icons.security, color: AppTheme.neonBlue, size: widget.size * 0.25),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final isActive    = i == currentStep;
            final isCompleted = i < currentStep;
            final color = isCompleted ? AppTheme.neonGreen
                        : isActive    ? AppTheme.neonBlue
                        : AppTheme.divider;
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive || isCompleted
                    ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                    : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            stepLabels.length,
            (i) => Text(
              stepLabels[i],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
  color: i <= currentStep
      ? AppTheme.neonBlue
      : AppTheme.textSecondary,
  fontSize: 9,
 ),
            ),
          ),
        ),
      ],
    );
  }
}
