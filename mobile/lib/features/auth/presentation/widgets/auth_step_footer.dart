import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';

/// Adımlar arası yan yana Geri + Devam Et butonları.
class AuthStepFooter extends StatelessWidget {
  const AuthStepFooter({
    super.key,
    required this.onBack,
    required this.onContinue,
    this.continueLabel = 'Devam Et',
    this.isLoading = false,
    this.primaryColor = AppColors.teacherPrimary,
    this.continueEnabled = true,
  });

  final VoidCallback onBack;
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool isLoading;
  final Color primaryColor;
  final bool continueEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            label: 'Geri',
            onPressed: isLoading ? null : onBack,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: PrimaryButton(
            label: continueLabel,
            onPressed: (isLoading || !continueEnabled) ? null : onContinue,
            isLoading: isLoading,
            backgroundColor: primaryColor,
          ),
        ),
      ],
    );
  }
}
