import 'package:flutter/material.dart';
import 'package:throttle_ui/features/settings/presentation/screens/subscription_screen.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeController get _themeController => ThemeController.instance;

  Future<void> _openThemePicker() async {
    final current = _themeController.theme;
    final primaryController = TextEditingController(
      text: _toHex(current.primary),
    );
    final secondaryController = TextEditingController(
      text: _toHex(current.secondary),
    );
    final tertiaryController = TextEditingController(
      text: _toHex(current.tertiary),
    );
    final backgroundController = TextEditingController(
      text: _toHex(current.background),
    );
    final surfaceController = TextEditingController(
      text: _toHex(current.surface),
    );
    final textController = TextEditingController(
      text: _toHex(current.textPrimary),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> applyCustomTheme() async {
              final primary = _parseHex(primaryController.text);
              final secondary = _parseHex(secondaryController.text);
              final tertiary = _parseHex(tertiaryController.text);
              final background = _parseHex(backgroundController.text);
              final surface = _parseHex(surfaceController.text);
              final text = _parseHex(textController.text);

              if ([
                primary,
                secondary,
                tertiary,
                background,
                surface,
                text,
              ].contains(null)) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text("Use valid hex colors like #7D39EB"),
                  ),
                );
                return;
              }

              await _themeController.applyCustom(
                primary: primary!,
                secondary: secondary!,
                tertiary: tertiary!,
                background: background!,
                surface: surface!,
                textPrimary: text!,
              );
              if (!mounted || !sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              setState(() {});
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Themes",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...ThemeController.presets.map((theme) {
                      final isSelected =
                          _themeController.theme.preset == theme.preset;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.overlay,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderSoft,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            theme.label,
                            style: const TextStyle(color: AppColors.white),
                          ),
                          subtitle: Text(
                            theme.fontFamily ?? "Default font",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              _swatch(theme.primary),
                              _swatch(theme.secondary),
                              _swatch(theme.surface),
                            ],
                          ),
                          onTap: () async {
                            await _themeController.applyPreset(theme.preset);
                            if (!mounted || !sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            setState(() {});
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    const Text(
                      "Custom Theme",
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _colorField("Primary", primaryController),
                    _colorField("Secondary", secondaryController),
                    _colorField("Tertiary", tertiaryController),
                    _colorField("Background", backgroundController),
                    _colorField("Surface", surfaceController),
                    _colorField("Text", textController),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: applyCustomTheme,
                        child: const Text("Apply Custom Theme"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _toHex(Color color) {
    return "#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}";
  }

  Color? _parseHex(String value) {
    final cleaned = value.replaceAll("#", "").trim();
    if (cleaned.length != 6) return null;
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed == null) return null;
    return Color(0xFF000000 | parsed);
  }

  Widget _swatch(Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white12),
      ),
    );
  }

  Widget _colorField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: "#7D39EB",
          hintStyle: const TextStyle(color: AppColors.textHint),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeController.theme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Settings",
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openThemePicker,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.16,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.palette_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Appearance",
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textHint,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            theme.label,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Choose from 3 presets or build your own colors.",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _swatch(theme.primary),
                              const SizedBox(width: 8),
                              _swatch(theme.secondary),
                              const SizedBox(width: 8),
                              _swatch(theme.surface),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.overlay,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.borderSoft,
                                  ),
                                ),
                                child: const Text(
                                  "Change Theme",
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: AppColors.white,
                    ),
                    title: const Text(
                      "Notifications",
                      style: TextStyle(color: AppColors.white),
                    ),
                    subtitle: const Text(
                      "Manage alerts",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.message, color: AppColors.white),
                    title: const Text(
                      "Messages",
                      style: TextStyle(color: AppColors.white),
                    ),
                    subtitle: const Text(
                      "Chat settings",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people, color: AppColors.white),
                    title: const Text(
                      "Followers",
                      style: TextStyle(color: AppColors.white),
                    ),
                    subtitle: const Text(
                      "Manage connections",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.directions_bike,
                      color: AppColors.white,
                    ),
                    title: const Text(
                      "My Bikes",
                      style: TextStyle(color: AppColors.white),
                    ),
                    subtitle: const Text(
                      "Add or edit bikes",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.shield, color: AppColors.white),
                    title: const Text(
                      "Privacy",
                      style: TextStyle(color: AppColors.white),
                    ),
                    subtitle: const Text(
                      "Data & security",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      "Subscription",
                      style: TextStyle(color: AppColors.white),
                    ),
                    subtitle: const Text(
                      "Manage your subscription plan",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubscriptionScreen(
                              onClose: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(80, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Manage"),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text("Log Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
