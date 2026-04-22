import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/theme_service.dart';

class AppColors {
  // Graceful fallback helper so tests or instances where Get isn't ready don't throw
  static bool get _isDark {
    try {
      return ThemeService.to.isDarkMode.value;
    } catch (_) {
      try {
        return Get.isDarkMode;
      } catch (_) {
        return false; // Default behavior
      }
    }
  }

  // Brand static colors (no light/dark split needed)
  static const Color cta1 = Color(0xFFFF501A); // #FF501A
  static const Color cta2 = Color(0xFFFE450C); // #FE450C
  static const Color highlight = Color(0xFFEFFF1B); // #EFFF1B
  static const Color highlight2 = Color(0xFFC558FE); // #C558FE

  // Backgrounds
  static Color get mainBackground => _isDark ? const Color(0xFF131313) : const Color(0xFFF7F7F7);
  static Color get background2 => _isDark ? const Color(0xFF383838) : const Color(0xFFF0F0F0);
  static Color get cardBackground => _isDark ? const Color(0xFF242424) : const Color(0xFFFFFFFF);
  static Color get textFieldBackground => _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFFFF);

  static Color get background => mainBackground;
  static Color get surface => background2;

  // Text Colors
  static Color get text1 => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF131313);
  static Color get text2 => _isDark ? const Color(0xFFDDD9D9) : const Color(0xFF5A5A5A);
  static Color get text3 => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000); // originally specifically black used for content

  // Standard generic text roles
  static Color get textPrimary => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);
  static Color get textSecondary => _isDark ? const Color(0xB3FFFFFF) : const Color(0x99000000);
  static Color get textLight => _isDark ? const Color(0x80FFFFFF) : const Color(0x66000000);

  static Color get primaryText => text1;
  static Color get primaryLight => text2;

  // Legacy primary/secondary mappings
  static Color get primary => cta1;
  static Color get secondary => highlight;
  static Color get secondaryDark => highlight2;
  static Color get secondaryLight => text2;

  // Status Colors
  static Color get success => cta1;
  static Color get warning => highlight;
  static Color get error => const Color(0xFFFF3B30);
  static Color get info => background2;

  // Borders and Dividers
  static Color get border => _isDark ? const Color(0x33FFFFFF) : const Color(0x1A000000);
  static Color get divider => _isDark ? const Color(0x26FFFFFF) : const Color(0x1F000000);
  static Color get shadow => _isDark ? const Color(0x40000000) : const Color(0x1A000000);

  // Platform buttons
  static Color get appleButton => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  static Color get appleButtonText => _isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  static Color get googleButton => const Color(0xFFFFFFFF);
  static Color get googleButtonText => const Color(0xFF000000);
}
