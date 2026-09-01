import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 6 haneli OTP girişi.
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.controller,
    this.onCompleted,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  static const _length = 6;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: AppTextStyles.h2.copyWith(letterSpacing: 12),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(_length),
      ],
      decoration: InputDecoration(
        hintText: '• • • • • •',
        hintStyle: AppTextStyles.h3.copyWith(
          color: AppColors.textSecondary.withAlpha(128),
          letterSpacing: 8,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) {
        if (v == null || v.length != _length) {
          return '6 haneli doğrulama kodunu girin.';
        }
        return null;
      },
      onChanged: (v) {
        if (v.length == _length) {
          widget.onCompleted?.call(v);
        }
      },
    );
  }
}
