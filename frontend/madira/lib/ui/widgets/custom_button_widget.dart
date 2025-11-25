import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

enum ButtonSize { small, medium, large }

enum ButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  success,
  warning,
  danger,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final bool enabled;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && !isLoading && onPressed != null;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: _buildButton(isEnabled),
    );
  }

  Widget _buildButton(bool isEnabled) {
    switch (variant) {
      case ButtonVariant.primary:
        return _buildPrimaryButton(isEnabled);
      case ButtonVariant.secondary:
        return _buildSecondaryButton(isEnabled);
      case ButtonVariant.outlined:
        return _buildOutlinedButton(isEnabled);
      case ButtonVariant.text:
        return _buildTextButton(isEnabled);
      case ButtonVariant.success:
        return _buildSuccessButton(isEnabled);
      case ButtonVariant.warning:
        return _buildWarningButton(isEnabled);
      case ButtonVariant.danger:
        return _buildDangerButton(isEnabled);
    }
  }

  Widget _buildPrimaryButton(bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: _getTextStyle(),
      ),
      child: _buildButtonContent(Colors.white),
    );
  }

  Widget _buildSecondaryButton(bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled
                ? AppColors.secondary
                : AppColors.textSecondary.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: _getTextStyle(),
      ),
      child: _buildButtonContent(Colors.white),
    );
  }

  Widget _buildOutlinedButton(bool isEnabled) {
    final color = isEnabled ? AppColors.primary : AppColors.textSecondary;
    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: color.withOpacity(isEnabled ? 0.3 : 0.5),
          width: 1,
        ),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: _getTextStyle(),
      ),
      child: _buildButtonContent(color),
    );
  }

  Widget _buildTextButton(bool isEnabled) {
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor:
            isEnabled ? AppColors.primary : AppColors.textSecondary,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: _getTextStyle(),
      ),
      child: _buildButtonContent(
        isEnabled ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSuccessButton(bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled
                ? AppColors.success
                : AppColors.textSecondary.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: _getTextStyle(),
      ),
      child: _buildButtonContent(Colors.white),
    );
  }

  Widget _buildWarningButton(bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled
                ? AppColors.warning
                : AppColors.textSecondary.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: _getTextStyle(),
      ),
      child: _buildButtonContent(Colors.white),
    );
  }

  Widget _buildDangerButton(bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: _getTextStyle(),
      ),
      child: _buildButtonContent(Colors.white),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text, style: _getTextStyle()),
        ],
      );
    }

    return Text(text, style: _getTextStyle());
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 7);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 14);
    }
  }

  TextStyle _getTextStyle() {
    double fontSize;
    switch (size) {
      case ButtonSize.small:
        fontSize = 12;
        break;
      case ButtonSize.medium:
        fontSize = 13;
        break;
      case ButtonSize.large:
        fontSize = 14;
        break;
    }

    return GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
      letterSpacing: -0.3,
    );
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }
}

// Specialized button widgets for common use cases
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonSize size;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.primary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonSize size;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.secondary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }
}

class OutlinedCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonSize size;

  const OutlinedCustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.outlined,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }
}

class IconButtonCustom extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final ButtonSize size;

  const IconButtonCustom({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    double iconSize;
    double padding;

    switch (size) {
      case ButtonSize.small:
        iconSize = 16;
        padding = 6;
        break;
      case ButtonSize.medium:
        iconSize = 18;
        padding = 8;
        break;
      case ButtonSize.large:
        iconSize = 20;
        padding = 10;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: IconButton(
        icon: Icon(icon, size: iconSize, color: color ?? AppColors.primary),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.all(padding),
        splashRadius: iconSize + padding,
      ),
    );
  }
}

class FloatingActionButtonCustom extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const FloatingActionButtonCustom({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 24),
    );
  }
}
