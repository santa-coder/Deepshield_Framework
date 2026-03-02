import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({super.key, required this.currentStep, this.totalSteps = 5});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 1,
              color: i ~/ 2 < currentStep - 1 ? AppTheme.neonBlue : AppTheme.divider,
            ),
          );
        }
        final step = i ~/ 2;
        final active = step == currentStep - 1;
        final done = step < currentStep - 1;
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppTheme.neonBlue : active ? AppTheme.neonBlue.withValues(alpha: 0.2) : AppTheme.surface,
            border: Border.all(
              color: active || done ? AppTheme.neonBlue : AppTheme.cardBorder,
              width: 1.5,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 14, color: AppTheme.background)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: active ? AppTheme.neonBlue : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
