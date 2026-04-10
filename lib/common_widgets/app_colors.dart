import 'package:flutter/material.dart';

class AppColors {
  // Palette from user
  // Main background
  static const Color mainBackground = Color(0xFF131313); // #131313

  // Background 2
  static const Color background2 = Color(0xFF383838); // #383838

  // CTA Colors
  static const Color cta1 = Color(0xFFFF501A); // #FF501A
  static const Color cta2 = Color(0xFFFE450C); // #FE450C

  // Text Colors
  static const Color text1 = Color(0xFFFFFFFF); // #FFFFFF
  static const Color text2 = Color(0xFFDDD9D9); // #DDD9D9
  static const Color text3 = Color(0xFF000000); // black for light surfaces

  // Highlight Colors
  static const Color highlight = Color(0xFFEFFF1B); // #EFFF1B
  static const Color highlight2 = Color(0xFFC558FE); // #C558FE

  // Legacy mappings for backward compatibility
  static const Color primary = cta1;
  static const Color primaryText = text1;
  static const Color primaryLight = text2;
  static const Color textFieldBackground = Color(
    0xFFF5F5F5,
  ); // Light gray for better contrast

  static const Color secondary = highlight;
  static const Color secondaryDark = highlight2;
  static const Color secondaryLight = text2;

  static const Color background = mainBackground;
  static const Color surface = background2;
  static const Color cardBackground = Color(0xFFFFFFFF); // cards use white

  // Text on light surfaces (cards, inputs) should be dark
  static const Color textPrimary = text3; // primary text on light bg
  static const Color textSecondary = Color(0x99000000); // 60% black
  static const Color textLight = Color(0x66000000); // 40% black

  // Status Colors (keeping existing for functionality)
  static const Color success = cta1;
  static const Color warning = highlight; // neon yellow draws attention
  static const Color error = Color(0xFFFF3B30); // red for errors
  static const Color info = background2;

  // Border Colors
  static const Color border = Color(0x1A000000); // 10% black on light cards
  static const Color divider = Color(0x1F000000); // 12% black

  // Platform buttons
  static const Color appleButton = Color(0xFF000000);
  static const Color appleButtonText = Color(0xFFFFFFFF);

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
}
