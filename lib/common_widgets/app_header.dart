import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? topSubtitle;
  final String? subtitle;
  final String? additionalSubtitle;
  final List<Widget>? actions;
  final Widget? customBottomContent;
  final double? fontSize;
  final double horizontalPadding;
  final double bottomPadding;

  const AppHeader({
    super.key,
    required this.title,
    this.topSubtitle,
    this.subtitle,
    this.additionalSubtitle,
    this.actions,
    this.customBottomContent,
    this.fontSize = 28,
    this.horizontalPadding = 16,
    this.bottomPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.98),
            AppColors.primary.withOpacity(0.78),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topInset + 16,
        horizontalPadding,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: topSubtitle != null
                    ? Text(
                        topSubtitle!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.text1,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (actions != null && actions!.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
            ],
          ),
          if (topSubtitle != null) const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.text1,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
            ),
          ),
          if (subtitle != null || additionalSubtitle != null || customBottomContent != null)
            const SizedBox(height: 6),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text1.withOpacity(0.9),
              ),
            ),
          if (additionalSubtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              additionalSubtitle!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text1.withOpacity(0.9),
              ),
            ),
          ],
          if (customBottomContent != null) ...[
            const SizedBox(height: 6),
            customBottomContent!,
          ],
        ],
      ),
    );
  }
}
