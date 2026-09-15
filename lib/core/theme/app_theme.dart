import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
    textTheme: const TextTheme(
      headlineLarge: AppTypography.display,
      headlineMedium: AppTypography.h1,
      titleLarge: AppTypography.h2,
      titleMedium: AppTypography.h3,
      titleSmall: AppTypography.bodyMedium,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.caption,
      labelLarge: AppTypography.button,
      labelMedium: AppTypography.bodyMedium,
      labelSmall: AppTypography.caption,
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: AppTypography.h3.copyWith(color: AppColors.surface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStatePropertyAll(
        AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: AppTypography.button,
      unselectedLabelStyle: AppTypography.bodyMedium,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(textStyle: AppTypography.button),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadii.input,
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.input,
        borderSide: const BorderSide(color: AppColors.divider),
      ),
    ),
  );
}
