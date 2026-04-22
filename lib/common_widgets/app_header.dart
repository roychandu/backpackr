import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

import '../screens/profile_screen/profile_screen.dart';

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
  final bool showProfileAvatar;

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
    this.showProfileAvatar = true,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (topSubtitle != null) ...[
                      Text(
                        topSubtitle!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.text1,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.text1,
                        fontWeight: FontWeight.w800,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions != null && actions!.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              if (showProfileAvatar)
                Padding(
                  padding: EdgeInsets.only(left: (actions != null && actions!.isNotEmpty) ? 12 : 0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.2), // Explicit contrast color against Orange gradient
                      child: Icon(
                        Icons.person,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
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
