import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter/services.dart';

class CustomInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;
  final int maxLines;
  final bool enabled;
  final String? errorText;
  final bool required;

  const CustomInputWidget({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.enabled = true,
    this.errorText,
    this.required = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        if (labelText.isNotEmpty) ...[
          RichText(
            text: TextSpan(
              text: labelText,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              children: [
                if (required)
                  TextSpan(
                    text: ' *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Text Field
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          maxLines: maxLines,
          enabled: enabled,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            prefixIcon:
                prefixIcon != null
                    ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: prefixIcon,
                    )
                    : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: suffixIcon,
            errorText: errorText,
            errorStyle: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),

            // Border styling
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.surfaceVariant.withOpacity(0.5),
                width: 1,
              ),
            ),

            // Fill styling
            filled: true,
            fillColor:
                enabled
                    ? AppColors.surface
                    : AppColors.surfaceVariant.withOpacity(0.3),

            // Content padding
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 14 : 12,
            ),
          ),
        ),
      ],
    );
  }
}

class PasswordInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool required;
  final String? errorText;

  const PasswordInputWidget({
    Key? key,
    required this.controller,
    this.labelText = 'Password',
    this.validator,
    this.onChanged,
    this.required = false,
    this.errorText,
  }) : super(key: key);

  @override
  State<PasswordInputWidget> createState() => _PasswordInputWidgetState();
}

class _PasswordInputWidgetState extends State<PasswordInputWidget> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomInputWidget(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: 'Enter your password',
      obscureText: _obscureText,
      prefixIcon: Icon(
        Icons.lock_outline,
        color: AppColors.textSecondary,
        size: 18,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
          size: 18,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      validator: widget.validator,
      onChanged: widget.onChanged,
      required: widget.required,
      errorText: widget.errorText,
    );
  }
}

class SearchInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;

  const SearchInputWidget({
    Key? key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomInputWidget(
      controller: controller,
      labelText: '',
      hintText: hintText,
      prefixIcon: Icon(
        Icons.search_outlined,
        color: AppColors.textSecondary,
        size: 18,
      ),
      suffixIcon:
          controller.text.isNotEmpty
              ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                onPressed: () {
                  controller.clear();
                  if (onClear != null) onClear!();
                  if (onChanged != null) onChanged!('');
                },
              )
              : null,
      onChanged: onChanged,
    );
  }
}

class PhoneNumber {
  final String? isoCode;
  final String? phoneNumber;
  const PhoneNumber({this.isoCode, this.phoneNumber});
}

class PhoneInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool required;
  final String labelText;
  final String? errorText;
  final void Function(PhoneNumber)? onChanged;

  const PhoneInputWidget({
    super.key,
    required this.controller,
    this.required = false,
    this.labelText = 'Phone number',
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText.isNotEmpty)
          RichText(
            text: TextSpan(
              text: labelText,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              children: [
                if (required)
                  TextSpan(
                    text: ' *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: (raw) {
            final digits = raw.replaceAll(RegExp(r'\D'), '');
            final e164 = '+213$digits';
            if (onChanged != null) {
              onChanged!(PhoneNumber(isoCode: 'DZ', phoneNumber: e164));
            }
          },
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return 'Phone is required';
            }
            final len = value?.length ?? 0;
            if (len < 9) return 'Enter at least 9 digits';
            return null;
          },
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: '0XXXXXXXXX',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.phone_outlined,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            errorText: errorText,
            errorStyle: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class AmountInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool required;
  final String labelText;
  final String? hintText;
  final String? errorText;
  final void Function(String)? onChanged;

  const AmountInputWidget({
    super.key,
    required this.controller,
    this.required = false,
    this.labelText = 'Amount',
    this.hintText,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final signAndDigits = FilteringTextInputFormatter.allow(
      RegExp(r'^[\+\-]?\d*$'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText.isNotEmpty)
          RichText(
            text: TextSpan(
              text: labelText,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              children: [
                if (required)
                  TextSpan(
                    text: ' *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: false,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          inputFormatters: <TextInputFormatter>[
            signAndDigits,
            LengthLimitingTextInputFormatter(12),
          ],
          onChanged: onChanged,
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return 'Amount is required';
            }
            if (value != null && value.isNotEmpty) {
              final normalized = value.replaceAll(' ', '');
              if (!RegExp(r'^[\+\-]?\d+$').hasMatch(normalized)) {
                return 'Enter a valid amount';
              }
            }
            return null;
          },
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText ?? '+2000 or -2000',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.account_balance_wallet,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            errorText: errorText,
            errorStyle: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
