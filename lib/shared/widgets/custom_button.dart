import 'package:flutter/material.dart';
import 'package:backpackr/shared/widgets/app_colors.dart';
import 'package:backpackr/shared/widgets/app_text_styles.dart';

/// A unified button widget that covers every button pattern in the app.
///
/// Variants:
/// - **Filled** (default): solid `backgroundColor`, white label.
/// - **Gradient**: cta1→cta2 gradient fill (set `isGradient: true`).
/// - **Outlined**: transparent fill, colored border (set `isOutlined: true`).
/// - **Text-only**: no background, no border (set `isTextOnly: true`).
///
/// Platform icon buttons (Apple, Google) are handled via `iconWidget`.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Renders a transparent-fill outlined button.
  final bool isOutlined;

  /// Renders a cta1→cta2 gradient filled button.
  final bool isGradient;

  /// Renders a bare text-only button (like Flutter's TextButton).
  final bool isTextOnly;

  final Color? backgroundColor;
  final Color? textColor;

  /// Border color for outlined buttons. Defaults to [backgroundColor] or [AppColors.primary].
  final Color? borderColor;

  final double? width;
  final double height;
  final double borderRadius;

  /// Leading icon from Material icons.
  final IconData? icon;

  /// Arbitrary leading widget (e.g. Image.asset for Google logo, Icon for Apple).
  final Widget? iconWidget;

  final bool isFullWidth;

  /// Button elevation. Defaults to 0 for flat modern look.
  final double elevation;

  /// Custom content padding.
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isGradient = false,
    this.isTextOnly = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.height = 48,
    this.borderRadius = 12,
    this.icon,
    this.iconWidget,
    this.isFullWidth = false,
    this.elevation = 0,
    this.padding,
  });

  // ─── Color resolution ───────────────────────────────────────────────────────

  Color _resolveTextColor() {
    if (textColor != null) return textColor!;
    if (isTextOnly) return backgroundColor ?? AppColors.primary;
    if (isOutlined) return borderColor ?? backgroundColor ?? AppColors.primary;
    // Gradient and filled → white label for contrast.
    return Colors.white;
  }

  Color _resolveBorderColor() =>
      borderColor ?? backgroundColor ?? AppColors.primary;

  Color _resolveBgColor() => backgroundColor ?? AppColors.primary;

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final Color labelColor = _resolveTextColor();
    Widget button;

    if (isTextOnly) {
      button = _buildTextButton(labelColor);
    } else if (isOutlined) {
      button = _buildOutlinedButton(labelColor);
    } else if (isGradient) {
      button = _buildGradientButton(labelColor);
    } else {
      button = _buildFilledButton(labelColor);
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, height: height, child: button);
    } else if (width != null) {
      return SizedBox(width: width, height: height, child: button);
    } else {
      return SizedBox(height: height, child: button);
    }
  }

  // ─── Variants ────────────────────────────────────────────────────────────────

  Widget _buildFilledButton(Color labelColor) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _resolveBgColor(),
        foregroundColor: labelColor,
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
      ),
      child: _buildContent(labelColor),
    );
  }

  Widget _buildOutlinedButton(Color labelColor) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: labelColor,
        side: BorderSide(color: _resolveBorderColor(), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
      ),
      child: _buildContent(labelColor),
    );
  }

  Widget _buildGradientButton(Color labelColor) {
    // Gradient uses a transparent ElevatedButton shell with an Ink gradient child.
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.cta1, AppColors.cta2],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Container(
          alignment: Alignment.center,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildContent(labelColor),
        ),
      ),
    );
  }

  Widget _buildTextButton(Color labelColor) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: labelColor,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: _buildContent(labelColor),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────────────

  Widget _buildContent(Color labelColor) {
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

    final TextStyle labelStyle = AppTextStyles.buttonMedium.copyWith(
      color: labelColor,
    );

    final Widget? leading =
        iconWidget ??
        (icon != null ? Icon(icon, size: 20, color: labelColor) : null);

    if (leading != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 10),
          Text(text, style: labelStyle),
        ],
      );
    }

    return Text(text, style: labelStyle);
  }
}
