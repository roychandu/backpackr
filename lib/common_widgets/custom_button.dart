import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final IconData? icon;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.borderRadius = 8,
    this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve the label color:
    // - Explicitly provided textColor always wins.
    // - Outlined buttons default to the border/brand color.
    // - Filled buttons default to white so they contrast on colored backgrounds.
    final Color resolvedTextColor = textColor ??
        (isOutlined
            ? (backgroundColor ?? AppColors.primary)
            : Colors.white);

    Widget button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: resolvedTextColor,
              side: BorderSide(
                color: backgroundColor ?? AppColors.primary,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            child: _buildButtonContent(resolvedTextColor),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? AppColors.primary,
              foregroundColor: resolvedTextColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              elevation: 2,
            ),
            child: _buildButtonContent(resolvedTextColor),
          );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, height: height, child: button);
    } else if (width != null) {
      return SizedBox(width: width, height: height, child: button);
    } else {
      return SizedBox(height: height, child: button);
    }
  }

  Widget _buildButtonContent(Color labelColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(labelColor),
        ),
      );
    }

    final TextStyle labelStyle = AppTextStyles.buttonMedium.copyWith(color: labelColor);

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: labelColor),
          const SizedBox(width: 8),
          Text(text, style: labelStyle),
        ],
      );
    }

    return Text(text, style: labelStyle);
  }
}
