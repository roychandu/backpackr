import 'package:flutter/material.dart';
import 'app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation = 2,
    this.borderRadius = 12,
    this.backgroundColor,
    this.onTap,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = Card(
      elevation: elevation,
      margin: margin ?? const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: showBorder
            ? const BorderSide(color: AppColors.border, width: 1)
            : BorderSide.none,
      ),
      color: backgroundColor ?? AppColors.cardBackground,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
