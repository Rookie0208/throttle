import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreset {
  premiumConnectivity,
  kineticNavigator,
  material,
  coding,
  cartoon,
  custom,
}

class AppThemeConfig {
  final AppThemePreset preset;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Brightness brightness;
  final String? fontFamily;
  final String? headlineFontFamily;
  final String label;

  const AppThemeConfig({
    required this.preset,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.brightness,
    required this.label,
    this.fontFamily,
    this.headlineFontFamily,
  });

  AppThemeConfig copyWith({
    AppThemePreset? preset,
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Brightness? brightness,
    String? fontFamily,
    String? headlineFontFamily,
    String? label,
  }) {
    return AppThemeConfig(
      preset: preset ?? this.preset,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      brightness: brightness ?? this.brightness,
      fontFamily: fontFamily ?? this.fontFamily,
      headlineFontFamily: headlineFontFamily ?? this.headlineFontFamily,
      label: label ?? this.label,
    );
  }
}

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const _presetKey = "theme_preset";
  static const _customPrimaryKey = "theme_custom_primary";
  static const _customSecondaryKey = "theme_custom_secondary";
  static const _customTertiaryKey = "theme_custom_tertiary";
  static const _customBackgroundKey = "theme_custom_background";
  static const _customSurfaceKey = "theme_custom_surface";
  static const _customTextKey = "theme_custom_text";

  AppThemeConfig _theme = presets.first;
  AppThemeConfig get theme => _theme;

  static const List<AppThemeConfig> presets = [
    AppThemeConfig(
      preset: AppThemePreset.premiumConnectivity,
      label: "Premium Connectivity",
      primary: Color(0xff0047DE),
      secondary: Color(0xff3463F7),
      tertiary: Color(0xff4B600E),
      background: Color(0xffF4F7FC),
      surface: Color(0xffE7EEF8),
      textPrimary: Color(0xff191B22),
      brightness: Brightness.light,
      fontFamily: "Plus Jakarta Sans",
      headlineFontFamily: "Lexend",
    ),
    AppThemeConfig(
      preset: AppThemePreset.kineticNavigator,
      label: "Kinetic Navigator",
      primary: Color(0xff053421),
      secondary: Color(0xff536600),
      tertiary: Color(0xffB3D335),
      background: Color(0xffF9FAF8),
      surface: Color(0xffFFFFFF),
      textPrimary: Color(0xff191C1B),
      brightness: Brightness.light,
      fontFamily: "Plus Jakarta Sans",
      headlineFontFamily: "Lexend",
    ),
    AppThemeConfig(
      preset: AppThemePreset.material,
      label: "Material Theme",
      primary: Color(0xff4A90E2),
      secondary: Color(0xff62789A),
      tertiary: Color(0xffC28000),
      background: Color(0xff000000),
      surface: Color(0xff121212),
      textPrimary: Color(0xffF8F9FA),
      brightness: Brightness.dark,
      fontFamily: "Inter",
      headlineFontFamily: "Manrope",
    ),
    AppThemeConfig(
      preset: AppThemePreset.coding,
      label: "Coding Theme",
      primary: Color(0xffC6FF33),
      secondary: Color(0xff7D39EB),
      tertiary: Color(0xffFF8C00),
      background: Color(0xff000000),
      surface: Color(0xff101010),
      textPrimary: Color(0xffF5F3FF),
      brightness: Brightness.dark,
      fontFamily: "Courier",
      headlineFontFamily: "Courier",
    ),
    AppThemeConfig(
      preset: AppThemePreset.cartoon,
      label: "Cartoon Theme",
      primary: Color(0xffFFE100),
      secondary: Color(0xff0050CC),
      tertiary: Color(0xffBF070F),
      background: Color(0xffFCF8F9),
      surface: Color(0xffFFFFFF),
      textPrimary: Color(0xff1B1B1C),
      brightness: Brightness.light,
      fontFamily: "Plus Jakarta Sans",
      headlineFontFamily: "Spline Sans",
    ),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final presetName = prefs.getString(_presetKey);
    if (presetName == null) {
      _theme = presets.first;
      return;
    }

    final preset = AppThemePreset.values.firstWhere(
      (item) => item.name == presetName,
      orElse: () => AppThemePreset.material,
    );

    if (preset == AppThemePreset.custom) {
      _theme = AppThemeConfig(
        preset: AppThemePreset.custom,
        label: "Custom Theme",
        primary: Color(
          prefs.getInt(_customPrimaryKey) ?? const Color(0xff7D39EB).toARGB32(),
        ),
        secondary: Color(
          prefs.getInt(_customSecondaryKey) ??
              const Color(0xffC6FF33).toARGB32(),
        ),
        tertiary: Color(
          prefs.getInt(_customTertiaryKey) ??
              const Color(0xffC28000).toARGB32(),
        ),
        background: Color(
          prefs.getInt(_customBackgroundKey) ??
              const Color(0xff000000).toARGB32(),
        ),
        surface: Color(
          prefs.getInt(_customSurfaceKey) ?? const Color(0xff18102B).toARGB32(),
        ),
        textPrimary: Color(
          prefs.getInt(_customTextKey) ?? const Color(0xffF5F3FF).toARGB32(),
        ),
        brightness: Brightness.dark,
        fontFamily: "Inter",
      );
      return;
    }

    _theme = presets.firstWhere((item) => item.preset == preset);
  }

  Future<void> applyPreset(AppThemePreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    final theme = presets.firstWhere((item) => item.preset == preset);
    _theme = theme;
    await prefs.setString(_presetKey, preset.name);
    notifyListeners();
  }

  Future<void> applyCustom({
    required Color primary,
    required Color secondary,
    required Color tertiary,
    required Color background,
    required Color surface,
    required Color textPrimary,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _theme = AppThemeConfig(
      preset: AppThemePreset.custom,
      label: "Custom Theme",
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      background: background,
      surface: surface,
      textPrimary: textPrimary,
      brightness: ThemeData.estimateBrightnessForColor(background),
      fontFamily: "Inter",
      headlineFontFamily: "Manrope",
    );

    await prefs.setString(_presetKey, AppThemePreset.custom.name);
    await prefs.setInt(_customPrimaryKey, primary.toARGB32());
    await prefs.setInt(_customSecondaryKey, secondary.toARGB32());
    await prefs.setInt(_customTertiaryKey, tertiary.toARGB32());
    await prefs.setInt(_customBackgroundKey, background.toARGB32());
    await prefs.setInt(_customSurfaceKey, surface.toARGB32());
    await prefs.setInt(_customTextKey, textPrimary.toARGB32());
    notifyListeners();
  }
}
