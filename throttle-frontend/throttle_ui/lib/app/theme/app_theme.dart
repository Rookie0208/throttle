import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'theme_controller.dart';

class AppTheme {
  static ThemeData buildTheme(AppThemeConfig config) {
    final isCartoon = config.preset == AppThemePreset.cartoon;
    final textSecondary = Color.lerp(
      config.textPrimary,
      config.background,
      isCartoon ? 0.32 : 0.25,
    )!;
    final textMuted = Color.lerp(
      config.textPrimary,
      config.background,
      isCartoon ? 0.48 : 0.45,
    )!;
    final border = isCartoon
        ? const Color(0xff000000)
        : Color.lerp(config.primary, config.surface, 0.65)!;
    final borderSoft = isCartoon
        ? const Color(0xff000000)
        : Color.lerp(config.surface, config.textPrimary, 0.15)!;
    final onPrimary =
        ThemeData.estimateBrightnessForColor(config.primary) == Brightness.dark
        ? AppColors.white
        : config.textPrimary;
    final onSecondary =
        ThemeData.estimateBrightnessForColor(config.secondary) ==
            Brightness.dark
        ? AppColors.white
        : config.textPrimary;
    final onTertiary =
        ThemeData.estimateBrightnessForColor(config.tertiary) == Brightness.dark
        ? AppColors.white
        : config.textPrimary;
    final baseTextTheme = _bodyTextTheme(config.fontFamily);
    final displayTextTheme = _headlineTextTheme(
      config.headlineFontFamily,
      baseTextTheme,
    );
    final buttonRadius = isCartoon ? 999.0 : 20.0;
    final inputRadius = isCartoon ? 28.0 : 18.0;
    final panelRadius = isCartoon ? 24.0 : 28.0;
    final surfaceColor = isCartoon ? const Color(0xffF6F3F4) : config.surface;
    final focusedInputFill = isCartoon
        ? config.secondary.withValues(alpha: 0.10)
        : config.surface;
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
      fontFamily: _resolvedFontFamily(config.fontFamily),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: pageTransitionsTheme,
      colorScheme: ColorScheme(
        brightness: config.brightness,
        primary: config.primary,
        onPrimary: onPrimary,
        secondary: config.secondary,
        onSecondary: onSecondary,
        surface: surfaceColor,
        onSurface: config.textPrimary,
        error: AppColors.error,
        onError: AppColors.white,
        tertiary: config.tertiary,
        onTertiary: onTertiary,
        outline: border,
        outlineVariant: borderSoft,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: config.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _headlineStyle(
          config.headlineFontFamily,
          color: config.textPrimary,
          fontSize: isCartoon ? 22 : 20,
          fontWeight: FontWeight.w800,
          letterSpacing: isCartoon ? -0.4 : 0,
        ),
        iconTheme: IconThemeData(color: config.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        focusColor: focusedInputFill,
        hintStyle: _bodyStyle(
          config.fontFamily,
          color: textMuted,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: _bodyStyle(
          config.fontFamily,
          color: textSecondary,
          fontWeight: isCartoon ? FontWeight.w700 : FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: borderSoft, width: isCartoon ? 3 : 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: borderSoft, width: isCartoon ? 3 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(
            color: isCartoon ? border : config.primary,
            width: isCartoon ? 3 : 1.5,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      cardColor: surfaceColor,
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(panelRadius),
          side: BorderSide(color: border, width: isCartoon ? 3 : 1),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(panelRadius),
          side: BorderSide(color: border, width: isCartoon ? 3 : 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(panelRadius),
          ),
          side: BorderSide(color: border, width: isCartoon ? 3 : 1),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCartoon ? 24 : 20),
          side: BorderSide(color: border, width: isCartoon ? 3 : 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: _bodyStyle(
          config.fontFamily,
          color: config.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCartoon ? 24 : 18),
          side: BorderSide(color: border, width: isCartoon ? 3 : 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: config.textPrimary,
        textColor: config.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 10,
        shape: const RoundedRectangleBorder(
          side: BorderSide.none,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: config.primary,
        linearTrackColor: surfaceColor,
      ),
      iconTheme: IconThemeData(color: config.textPrimary),
      dividerColor: borderSoft.withValues(alpha: isCartoon ? 0.55 : 0.35),
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
          color: config.primary.withValues(alpha: isCartoon ? 0.28 : 0.14),
          borderRadius: BorderRadius.circular(isCartoon ? 999 : 16),
          border: isCartoon ? Border.all(color: border, width: 3) : null,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: config.primary,
        unselectedLabelColor: textMuted,
        labelStyle: _headlineStyle(
          config.headlineFontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: isCartoon ? 0.2 : 0,
        ),
        unselectedLabelStyle: _headlineStyle(
          config.headlineFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        dividerColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: config.primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor.withValues(alpha: 0.98),
        indicatorColor: config.primary.withValues(
          alpha: isCartoon ? 0.28 : 0.14,
        ),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: isCartoon ? 84 : 78,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? config.primary : textMuted,
            size: selected ? 24 : 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return _headlineStyle(
            config.headlineFontFamily,
            color: selected ? config.primary : textMuted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: isCartoon ? 0.3 : 0.4,
          );
        }),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: border, width: isCartoon ? 3 : 0),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: config.primary,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCartoon ? 999 : 20),
          side: BorderSide(color: border, width: isCartoon ? 3 : 0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: config.textPrimary,
          backgroundColor: surfaceColor,
          side: BorderSide(color: borderSoft, width: isCartoon ? 3 : 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: _headlineStyle(
            config.headlineFontFamily,
            fontWeight: isCartoon ? FontWeight.w800 : FontWeight.w700,
            fontSize: 14,
            letterSpacing: isCartoon ? 0.2 : 0,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
            side: BorderSide(color: border, width: isCartoon ? 3 : 0),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: _headlineStyle(
            config.headlineFontFamily,
            fontWeight: isCartoon ? FontWeight.w800 : FontWeight.w700,
            fontSize: 14,
            letterSpacing: isCartoon ? 0.2 : 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: config.primary,
          textStyle: _headlineStyle(
            config.headlineFontFamily,
            fontWeight: isCartoon ? FontWeight.w800 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      textTheme: displayTextTheme.copyWith(
        bodyLarge: _bodyStyle(
          config.fontFamily,
          color: config.textPrimary,
          fontSize: isCartoon ? 18 : 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: _bodyStyle(
          config.fontFamily,
          color: textSecondary,
          fontSize: isCartoon ? 16 : 14,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: _bodyStyle(
          config.fontFamily,
          color: textMuted,
          fontSize: 12,
          fontWeight: isCartoon ? FontWeight.w700 : FontWeight.w500,
        ),
        titleLarge: _headlineStyle(
          config.headlineFontFamily,
          color: config.textPrimary,
          fontWeight: isCartoon ? FontWeight.w800 : FontWeight.w700,
          fontSize: isCartoon ? 32 : 24,
          letterSpacing: isCartoon ? -0.4 : 0,
        ),
        titleMedium: _headlineStyle(
          config.headlineFontFamily,
          color: config.textPrimary,
          fontWeight: isCartoon ? FontWeight.w700 : FontWeight.w600,
          fontSize: isCartoon ? 24 : 18,
          letterSpacing: isCartoon ? -0.2 : 0,
        ),
        headlineMedium: _headlineStyle(
          config.headlineFontFamily,
          color: config.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: isCartoon ? 48 : 28,
          letterSpacing: isCartoon ? -0.8 : 0,
        ),
        labelMedium: _headlineStyle(
          config.headlineFontFamily,
          color: textSecondary,
          fontWeight: isCartoon ? FontWeight.w800 : FontWeight.w700,
          fontSize: 14,
          letterSpacing: isCartoon ? 0.2 : 0.5,
        ),
      ),
    );
  }

  static String? _resolvedFontFamily(String? family) {
    switch (family) {
      case "Plus Jakarta Sans":
        return GoogleFonts.plusJakartaSans().fontFamily;
      case "Spline Sans":
        return GoogleFonts.splineSans().fontFamily;
      case "Lexend":
        return GoogleFonts.lexend().fontFamily;
      case "Inter":
        return GoogleFonts.inter().fontFamily;
      case "Manrope":
        return GoogleFonts.manrope().fontFamily;
      default:
        return family;
    }
  }

  static TextTheme _bodyTextTheme(String? family) {
    switch (family) {
      case "Inter":
        return GoogleFonts.interTextTheme();
      case "Manrope":
        return GoogleFonts.manropeTextTheme();
      case "Spline Sans":
        return GoogleFonts.splineSansTextTheme();
      case "Lexend":
        return GoogleFonts.lexendTextTheme();
      case "Plus Jakarta Sans":
      default:
        return GoogleFonts.plusJakartaSansTextTheme();
    }
  }

  static TextTheme _headlineTextTheme(String? family, TextTheme base) {
    switch (family) {
      case "Spline Sans":
        return GoogleFonts.splineSansTextTheme(base);
      case "Inter":
        return GoogleFonts.interTextTheme(base);
      case "Manrope":
        return GoogleFonts.manropeTextTheme(base);
      case "Plus Jakarta Sans":
        return GoogleFonts.plusJakartaSansTextTheme(base);
      case "Lexend":
      default:
        return GoogleFonts.lexendTextTheme(base);
    }
  }

  static TextStyle _bodyStyle(
    String? family, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    switch (family) {
      case "Inter":
        return GoogleFonts.inter(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case "Manrope":
        return GoogleFonts.manrope(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case "Spline Sans":
        return GoogleFonts.splineSans(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case "Lexend":
        return GoogleFonts.lexend(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case "Plus Jakarta Sans":
      default:
        return GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
    }
  }

  static TextStyle _headlineStyle(
    String? family, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    switch (family) {
      case "Spline Sans":
        return GoogleFonts.splineSans(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case "Inter":
        return GoogleFonts.inter(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case "Manrope":
        return GoogleFonts.manrope(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case "Plus Jakarta Sans":
        return GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case "Lexend":
      default:
        return GoogleFonts.lexend(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
    }
  }
}
