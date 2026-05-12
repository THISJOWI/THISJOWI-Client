import 'package:flutter/material.dart';
import 'package:thisjowi/core/app_colors.dart';

class ThemeColors {
  static Color background(BuildContext context) {
    return AppColors.backgroundOf(context);
  }

  static Color text(BuildContext context) {
    return AppColors.textOf(context);
  }

  static Color surface(BuildContext context) {
    return AppColors.surfaceOf(context);
  }

  static Color bottomNavBar(BuildContext context) {
    return AppColors.bottomNavBarOf(context);
  }

  static Color primary = AppColors.primary;
  static Color secondary = AppColors.secondary;
  static Color accent = AppColors.accent;
}