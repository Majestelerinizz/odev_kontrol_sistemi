import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Adım ilerleme çubuğu (Multi-step Wizard Indicator)
class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
    this.primaryColor = AppColors.teacherPrimary,
  });

  final int currentStep; // 0-indexed
  final int totalSteps;
  final List<String> stepTitles;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Adım rozetleri & Çizgi
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentStep;
              final isActive = stepIndex == currentStep;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? primaryColor
                      : isActive
                          ? primaryColor.withAlpha(38)
                          : AppColors.surfaceVariant,
                  border: Border.all(
                    color: isActive || isCompleted
                        ? primaryColor
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.textOnPrimary,
                          size: 20,
                        )
                      : Text(
                          '${stepIndex + 1}',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isActive
                                ? primaryColor
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              );
            } else {
              final lineIndex = (index - 1) ~/ 2;
              final isPassed = lineIndex < currentStep;

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isPassed ? primaryColor : AppColors.border,
                  ),
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 12),
        // Aktif adım başlığı
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Adım ${currentStep + 1} / $totalSteps',
              style: AppTextStyles.labelSmall.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (currentStep < stepTitles.length)
              Text(
                stepTitles[currentStep],
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
