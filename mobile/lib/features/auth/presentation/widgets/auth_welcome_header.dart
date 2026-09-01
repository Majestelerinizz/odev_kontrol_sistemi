import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

/// Auth adımı başlık ve alt açıklama (giriş / kayıt moduna göre).
class AuthWelcomeHeader extends StatelessWidget {
  const AuthWelcomeHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h2),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: AppTextStyles.bodyMedium),
        ],
      ],
    );
  }
}
