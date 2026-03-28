import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'theme_controller.dart';

class AppTheme {
  static ThemeData buildTheme(AppThemeConfig config) {
    final textSecondary = Color.lerp(config.textPrimary, config.background, 0.25)!;
    final textMuted = Color.lerp(config.textPrimary, config.background, 0.45)!;
    final border = Color.lerp(config.primary, config.surface, 0.65)!;
    final borderSoft = Color.lerp(config.surface, config.textPrimary, 0.15)!;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: config.background,
      fontFamily: config.fontFamily,
      colorScheme: ColorScheme.dark(
        primary: config.primary,
        surface: config.surface,
        secondary: config.secondary,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: config.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: config.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: config.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: config.surface,
        hintStyle: TextStyle(color: textMuted),
        labelStyle: TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: config.primary),
        ),
      ),
      cardColor: config.surface,
      dialogTheme: DialogThemeData(
        backgroundColor: config.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: config.surface,
        contentTextStyle: TextStyle(color: config.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: config.textPrimary,
        textColor: config.textPrimary,
      ),
      iconTheme: IconThemeData(color: config.textPrimary),
      dividerColor: border,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: config.surface,
        selectedItemColor: config.primary,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: config.primary,
        foregroundColor: AppColors.white,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: config.textPrimary,
          side: BorderSide(color: borderSoft),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: config.primary,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: config.textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textMuted),
        titleLarge: TextStyle(
          color: config.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: config.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: textSecondary,
        ),
      ),
    );
  }
}
