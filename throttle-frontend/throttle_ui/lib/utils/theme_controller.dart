import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreset { material, coding, cartoon, custom }

class AppThemeConfig {
  final AppThemePreset preset;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final String? fontFamily;
  final String label;

  const AppThemeConfig({
    required this.preset,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.label,
    this.fontFamily,
  });

  AppThemeConfig copyWith({
    AppThemePreset? preset,
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? textPrimary,
    String? fontFamily,
    String? label,
  }) {
    return AppThemeConfig(
      preset: preset ?? this.preset,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      fontFamily: fontFamily ?? this.fontFamily,
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
  static const _customBackgroundKey = "theme_custom_background";
  static const _customSurfaceKey = "theme_custom_surface";
  static const _customTextKey = "theme_custom_text";

  AppThemeConfig _theme = presets.first;
  AppThemeConfig get theme => _theme;

  static const List<AppThemeConfig> presets = [
    AppThemeConfig(
      preset: AppThemePreset.material,
      label: "Material Theme",
      primary: Color(0xff7D39EB),
      secondary: Color(0xffC6FF33),
      background: Color(0xff000000),
      surface: Color(0xff18102B),
      textPrimary: Color(0xffF5F3FF),
      fontFamily: "Roboto",
    ),
    AppThemeConfig(
      preset: AppThemePreset.coding,
      label: "Coding Theme",
      primary: Color(0xffC6FF33),
      secondary: Color(0xff7D39EB),
      background: Color(0xff000000),
      surface: Color(0xff101010),
      textPrimary: Color(0xffF5F3FF),
      fontFamily: "Courier",
    ),
    AppThemeConfig(
      preset: AppThemePreset.cartoon,
      label: "Cartoon Theme",
      primary: Color(0xffF0E100),
      secondary: Color(0xff7D39EB),
      background: Color(0xff18102B),
      surface: Color(0xff2A1648),
      textPrimary: Color(0xffFFFFFF),
      fontFamily: "Trebuchet MS",
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
        primary: Color(prefs.getInt(_customPrimaryKey) ?? const Color(0xff7D39EB).value),
        secondary: Color(prefs.getInt(_customSecondaryKey) ?? const Color(0xffC6FF33).value),
        background: Color(prefs.getInt(_customBackgroundKey) ?? const Color(0xff000000).value),
        surface: Color(prefs.getInt(_customSurfaceKey) ?? const Color(0xff18102B).value),
        textPrimary: Color(prefs.getInt(_customTextKey) ?? const Color(0xffF5F3FF).value),
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
      background: background,
      surface: surface,
      textPrimary: textPrimary,
      fontFamily: "Roboto",
    );

    await prefs.setString(_presetKey, AppThemePreset.custom.name);
    await prefs.setInt(_customPrimaryKey, primary.value);
    await prefs.setInt(_customSecondaryKey, secondary.value);
    await prefs.setInt(_customBackgroundKey, background.value);
    await prefs.setInt(_customSurfaceKey, surface.value);
    await prefs.setInt(_customTextKey, textPrimary.value);
    notifyListeners();
  }
}
