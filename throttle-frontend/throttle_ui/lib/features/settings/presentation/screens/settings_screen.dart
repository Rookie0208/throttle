import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                    content: Text("Use valid hex colors like #0047DE"),
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
                        color: AppColors.textPrimary,
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
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderSoft,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12191B22),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            theme.label,
                            style: GoogleFonts.lexend(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            theme.fontFamily ?? "Default font",
                            style: GoogleFonts.plusJakartaSans(
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
                        color: AppColors.textPrimary,
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
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: "#0047DE",
          hintStyle: const TextStyle(color: AppColors.textHint),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeController.theme;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Settings")),
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
                      borderRadius: BorderRadius.circular(24),
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
                              Expanded(
                                child: Text(
                                  "Appearance",
                                  style: GoogleFonts.lexend(
                                    color: AppColors.textPrimary,
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
                            style: GoogleFonts.lexend(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Choose from 3 presets or build your own colors.",
                            style: GoogleFonts.plusJakartaSans(
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
                                    color: AppColors.textPrimary,
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
                    leading: Icon(
                      Icons.notifications_outlined,
                      color: colorScheme.primary,
                    ),
                    title: Text("Notifications", style: textTheme.titleMedium),
                    subtitle: Text("Manage alerts", style: textTheme.bodySmall),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.message_outlined,
                      color: colorScheme.primary,
                    ),
                    title: Text("Messages", style: textTheme.titleMedium),
                    subtitle: Text("Chat settings", style: textTheme.bodySmall),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.people_outline_rounded,
                      color: colorScheme.primary,
                    ),
                    title: Text("Followers", style: textTheme.titleMedium),
                    subtitle: Text(
                      "Manage connections",
                      style: textTheme.bodySmall,
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.two_wheeler_outlined,
                      color: colorScheme.primary,
                    ),
                    title: Text("My Bikes", style: textTheme.titleMedium),
                    subtitle: Text(
                      "Add or edit bikes",
                      style: textTheme.bodySmall,
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.shield_outlined,
                      color: colorScheme.primary,
                    ),
                    title: Text("Privacy", style: textTheme.titleMedium),
                    subtitle: Text(
                      "Data & security",
                      style: textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: AppColors.primary,
                    ),
                    title: Text("Subscription", style: textTheme.titleMedium),
                    subtitle: Text(
                      "Manage your subscription plan",
                      style: textTheme.bodySmall,
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
