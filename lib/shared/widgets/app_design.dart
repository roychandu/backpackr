// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:backpackr/shared/widgets/app_text_styles.dart';
import 'package:backpackr/shared/widgets/app_colors.dart';

// Spacing helpers
Widget gap8() => const SizedBox(height: 8);
Widget gap12() => const SizedBox(height: 12);

// Section header with gradient icon
Widget sectionHeader(String title, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.text1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

// Glassmorphism card wrapper
Widget glassCard({
  required List<Widget> children,
  EdgeInsets? padding,
  EdgeInsets? margin,
}) {
  return Container(
    margin: margin ?? const EdgeInsets.only(bottom: 16),
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.text1.withOpacity(0.08),
          AppColors.text1.withOpacity(0.04),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.text1.withOpacity(0.18), width: 1),
      boxShadow: [
        BoxShadow(
          color: AppColors.text3.withOpacity(0.10),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

// Label widget
Widget designLabel(String text) {
  return Text(
    text,
    style: AppTextStyles.bodySmall.copyWith(
      color: AppColors.text1.withOpacity(0.9),
      fontWeight: FontWeight.w600,
    ),
  );
}

// Text field decoration
InputDecoration glassInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.text1.withOpacity(0.55)),
    filled: true,
    fillColor: AppColors.text1.withOpacity(0.04),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.text1.withOpacity(0.22)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.highlight, width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.error),
    ),
  );
}

// Primary gradient button
Widget designPrimaryButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return Align(
    alignment: Alignment.center,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.highlight, AppColors.cta1],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.highlight.withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.text1),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.text1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
