import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../utils/phone_utils.dart';

/// +90 sabit prefix ile TR cep telefonu girişi (5XX XXX XX XX).
class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.validator,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool autofocus;

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Telefon', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          autofocus: widget.autofocus,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
            _PhoneDisplayFormatter(),
          ],
          decoration: InputDecoration(
            hintText: '5XX XXX XX XX',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+90',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 24,
                    color: AppColors.border,
                  ),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
            ),
          ),
          validator: widget.validator ??
              (v) {
                final digits = PhoneUtils.extractNationalDigits(v ?? '');
                if (!PhoneUtils.isValidNational(digits)) {
                  return 'Geçerli bir cep telefonu girin (5XX XXX XX XX).';
                }
                return null;
              },
          onChanged: (v) {
            widget.onChanged?.call(PhoneUtils.extractNationalDigits(v));
          },
        ),
      ],
    );
  }
}

class _PhoneDisplayFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = PhoneUtils.extractNationalDigits(newValue.text);
    final formatted = PhoneUtils.formatDisplay(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
