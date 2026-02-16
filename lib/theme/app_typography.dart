import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    return const TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  static TextStyle breadcrumbItem = TextStyle(
    fontWeight: FontWeight.w800,
    color: AppColors.blue800,
  );

  static const TextStyle sidebarHeader = TextStyle(
    color: AppColors.white,
    fontSize: 16,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle sidebarItem = TextStyle(
    color: AppColors.white,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );

  static TextStyle gridCardTitle = TextStyle(
    fontWeight: FontWeight.w900,
    color: AppColors.text,
    height: 1.15,
    fontSize: 12.5,
  );
}
