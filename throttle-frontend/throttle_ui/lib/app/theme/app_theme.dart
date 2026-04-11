import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'theme_controller.dart';

class AppTheme {
  static ThemeData buildTheme(AppThemeConfig config) {
    final textSecondary = Color.lerp(
      config.textPrimary,
      config.background,
      0.25,
    )!;
    final textMuted = Color.lerp(config.textPrimary, config.background, 0.45)!;
    final border = Color.lerp(config.primary, config.surface, 0.65)!;
    final borderSoft = Color.lerp(config.surface, config.textPrimary, 0.15)!;
    final isLight = config.brightness == Brightness.light;
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    final displayTextTheme = GoogleFonts.lexendTextTheme(baseTextTheme);
    final pageTransitionsTheme = PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const FadeForwardsPageTransitionsBuilder(),
      },
    );

    return ThemeData(
      useMaterial3: true,
      brightness: config.brightness,
      scaffoldBackgroundColor: config.background,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: pageTransitionsTheme,
      colorScheme: ColorScheme(
        brightness: config.brightness,
        primary: config.primary,
        onPrimary: isLight ? AppColors.white : config.textPrimary,
        secondary: config.secondary,
        onSecondary: config.textPrimary,
        surface: config.surface,
        onSurface: config.textPrimary,
        error: AppColors.error,
        onError: AppColors.white,
        tertiary: config.tertiary,
        onTertiary: config.textPrimary,
        outline: border,
        outlineVariant: borderSoft,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: config.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.lexend(
          color: config.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: config.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: config.surface,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textMuted,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: config.primary, width: 1.5),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      cardColor: config.surface,
      dialogTheme: DialogThemeData(
        backgroundColor: config.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: config.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: config.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: config.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: config.surface,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: config.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: config.textPrimary,
        textColor: config.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: config.primary,
        linearTrackColor: config.surface,
      ),
      iconTheme: IconThemeData(color: config.textPrimary),
      dividerColor: border,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: config.primary,
        selectionColor: config.primary.withValues(alpha: 0.18),
        selectionHandleColor: config.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return selected ? config.primary : AppColors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return selected
              ? config.primary.withValues(alpha: 0.35)
              : borderSoft.withValues(alpha: 0.8);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? config.primary
              : Colors.transparent;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStatePropertyAll(config.primary),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: config.primary,
        inactiveTrackColor: borderSoft,
        thumbColor: config.primary,
        overlayColor: config.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          color: config.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: config.primary,
        unselectedLabelColor: textMuted,
        labelStyle: GoogleFonts.lexend(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.lexend(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        dividerColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: config.surface,
        selectedItemColor: config.primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: config.surface.withValues(alpha: 0.96),
        indicatorColor: config.primary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? config.primary : textMuted,
            size: selected ? 24 : 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.lexend(
            color: selected ? config.primary : textMuted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.4,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 78,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: config.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: config.textPrimary,
          side: BorderSide(color: borderSoft),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: config.primary,
          textStyle: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: displayTextTheme.copyWith(
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: config.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: GoogleFonts.lexend(
          color: config.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        titleMedium: GoogleFonts.lexend(
          color: config.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        headlineMedium: GoogleFonts.lexend(
          color: config.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        labelMedium: GoogleFonts.lexend(
          color: textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
