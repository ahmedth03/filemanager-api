import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF1B4F72);
  static const Color primaryLight = Color(0xFF2E86C1);
  static const Color primaryDark = Color(0xFF154360);
  static const Color accent = Color(0xFFF39C12);
  static const Color accentLight = Color(0xFFF5B041);
  static const Color accentDark = Color(0xFFD68910);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF2C2C2C);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color textPrimaryDark = Color(0xFFF8F9FA);
  static const Color textSecondaryDark = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFD5F5E3);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDEDEC);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF9E7);
  static const Color info = Color(0xFF2980B9);
  static const Color infoLight = Color(0xFFD6EAF8);

  // Border Colors
  static const Color border = Color(0xFFDEE2E6);
  static const Color borderDark = Color(0xFF404040);
  static const Color divider = Color(0xFFE9ECEF);
  static const Color dividerDark = Color(0xFF333333);

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2C2C2C);
  static const Color shimmerHighlightDark = Color(0xFF3D3D3D);

  // Rating Colors
  static const Color starFilled = Color(0xFFF39C12);
  static const Color starEmpty = Color(0xFFDEE2E6);

  // Craft Category Colors
  static const Color plumberColor = Color(0xFF2980B9);
  static const Color electricianColor = Color(0xFFF39C12);
  static const Color carpenterColor = Color(0xFF8B4513);
  static const Color painterColor = Color(0xFF8E44AD);
  static const Color masonColor = Color(0xFF7F8C8D);
  static const Color tillerColor = Color(0xFF16A085);

  // Property Type Colors
  static const Color apartmentColor = Color(0xFF1B4F72);
  static const Color houseColor = Color(0xFF27AE60);
  static const Color studioColor = Color(0xFF8E44AD);
  static const Color commercialColor = Color(0xFFF39C12);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B4F72), Color(0xFF2E86C1)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x001B4F72), Color(0xCC1B4F72)],
  );
}
