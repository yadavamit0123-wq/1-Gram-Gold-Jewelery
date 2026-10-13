import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Secondary
  static const Color primary = Color(0xFF0B1325); // Deep Royal Navy
  static const Color primaryLight = Color(0xFF1B2A4A);
  static const Color primaryDark = Color(0xFF060A14);

  // Gold Accents (Trademark: 1 Gram Gold Jewellery)
  static const Color gold = Color(0xFFD97706); // Radiant Amber Gold
  static const Color goldLight = Color(0xFFFBBF24);
  static const Color goldDark = Color(0xFFB45309);
  static const Color goldAccent = Color(0xFFF59E0B);
  static const Color goldGradientStart = Color(0xFFF59E0B);
  static const Color goldGradientEnd = Color(0xFFD97706);

  // Neutrals & Backgrounds
  static const Color background = Color(0xFFFAF7F2); // Warm Cream
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF3F0EA);
  static const Color cardBg = Colors.white;
  static const Color border = Color(0xFFE5E0D8);
  static const Color borderLight = Color(0xFFF0EBE1);

  // Typography
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Colors.white;

  // Semantic & Status
  static const Color success = Color(0xFF059669); // Emerald Green
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFEAB308);
  static const Color info = Color(0xFF2563EB);

  // Badges & Highlights
  static const Color badgeDiscount = Color(0xFFDC2626);
  static const Color badgeNew = Color(0xFF059669);
  static const Color badgeBestseller = Color(0xFFD97706);
  static const Color starRating = Color(0xFFF59E0B);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldGradientStart, goldGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
