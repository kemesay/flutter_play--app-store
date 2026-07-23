import 'package:flutter/material.dart';

/// Spacing scale used app-wide instead of ad-hoc SizedBox values.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner-radius scale used app-wide instead of ad-hoc BorderRadius values.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Single source of truth for brand colors.
class AppColors {
  AppColors._();

  static const Color brand = Color(0xFF03930A);
  static const Color brandLight = Color(0xFF4CB051);
  static const Color brandDark = Color(0xFF2C8A90);
}
