import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

/// Ödev durum rozeti.
/// Renk + ikon + metin birlikte gösterir (Master Reference §17.4 kuralı).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  static _StatusConfig _getConfig(String status) {
    return switch (status) {
      'completed' => const _StatusConfig(
          label: 'Tamamlandı',
          color: AppColors.success,
          bgColor: AppColors.successLight,
          icon: Icons.check_circle_rounded,
        ),
      'missed' => const _StatusConfig(
          label: 'Yapılmadı',
          color: AppColors.error,
          bgColor: AppColors.errorLight,
          icon: Icons.cancel_rounded,
        ),
      'overdue' => const _StatusConfig(
          label: 'Gecikti',
          color: AppColors.statusOverdue,
          bgColor: Color(0xFFFFE4E4),
          icon: Icons.warning_rounded,
        ),
      _ => const _StatusConfig(
          label: 'Bekliyor',
          color: AppColors.warning,
          bgColor: AppColors.warningLight,
          icon: Icons.schedule_rounded,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final iconSize = compact ? 14.0 : 16.0;
    final fontSize = compact ? 12.0 : 13.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(AppSizes.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: config.color, size: iconSize),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: config.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });
}

/// Boş durum ekranı bileşeni
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_rounded,
                size: 40,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: action,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Hata durum ekranı bileşeni
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bir Hata Oluştu',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar Dene'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Yüklenme iskeleti bileşeni
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  const LoadingSkeleton.line({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  const LoadingSkeleton.circle({
    super.key,
    required double size,
    this.borderRadius,
  })  : width = size,
        height = size;

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: widget.borderRadius ??
                  BorderRadius.circular(widget.height / 2),
            ),
          ),
        );
      },
    );
  }
}

/// Onay diyalogu
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    this.cancelLabel = 'İptal',
    this.isDangerous = false,
  });

  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    String cancelLabel = 'İptal',
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDangerous: isDangerous,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDangerous
              ? ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
