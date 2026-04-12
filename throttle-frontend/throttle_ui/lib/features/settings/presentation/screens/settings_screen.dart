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
    final theme = _themeController.theme;
    final primaryController = TextEditingController(
      text: _toHex(theme.primary),
    );
    final secondaryController = TextEditingController(
      text: _toHex(theme.secondary),
    );
    final tertiaryController = TextEditingController(
      text: _toHex(theme.tertiary),
    );
    final backgroundController = TextEditingController(
      text: _toHex(theme.background),
    );
    final surfaceController = TextEditingController(
      text: _toHex(theme.surface),
    );
    final textController = TextEditingController(
      text: _toHex(theme.textPrimary),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.background,
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
                    Text(
                      "Themes",
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...ThemeController.presets.map((preset) {
                      final isSelected =
                          _themeController.theme.preset == preset.preset;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? theme.primary
                                : const Color(0x52B8C6DA),
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
                            preset.label,
                            style: GoogleFonts.lexend(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            preset.fontFamily ?? "Default font",
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.textPrimary.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              _swatch(preset.primary),
                              _swatch(preset.secondary),
                              _swatch(preset.surface),
                            ],
                          ),
                          onTap: () async {
                            await _themeController.applyPreset(preset.preset);
                            if (!mounted || !sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            setState(() {});
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    Text(
                      "Custom Theme",
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _colorField("Primary", primaryController, theme),
                    _colorField("Secondary", secondaryController, theme),
                    _colorField("Tertiary", tertiaryController, theme),
                    _colorField("Background", backgroundController, theme),
                    _colorField("Surface", surfaceController, theme),
                    _colorField("Text", textController, theme),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                        ),
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
        border: Border.all(color: const Color(0x52B8C6DA)),
      ),
    );
  }

  Widget _colorField(
    String label,
    TextEditingController controller,
    AppThemeConfig theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        style: TextStyle(color: theme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: "#0047DE",
          hintStyle: TextStyle(color: theme.textPrimary.withValues(alpha: 0.4)),
          labelStyle: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        final theme = _themeController.theme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            title: Text(
              "Settings",
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: IconThemeData(color: theme.textPrimary),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0x52B8C6DA)),
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
                                      color: theme.primary.withValues(
                                        alpha: 0.16,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.palette_outlined,
                                      color: theme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Appearance",
                                      style: GoogleFonts.lexend(
                                        color: theme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: theme.textPrimary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                theme.label,
                                style: GoogleFonts.lexend(
                                  color: theme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Choose from 3 presets or build your own colors.",
                                style: GoogleFonts.plusJakartaSans(
                                  color: theme.textPrimary.withValues(
                                    alpha: 0.65,
                                  ),
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
                                      color: theme.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: theme.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "Change Theme",
                                      style: TextStyle(
                                        color: theme.primary,
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
                      _settingsTile(
                        icon: Icons.notifications_outlined,
                        title: "Notifications",
                        subtitle: "Manage alerts",
                        theme: theme,
                      ),
                      _settingsTile(
                        icon: Icons.message_outlined,
                        title: "Messages",
                        subtitle: "Chat settings",
                        theme: theme,
                      ),
                      _settingsTile(
                        icon: Icons.people_outline_rounded,
                        title: "Followers",
                        subtitle: "Manage connections",
                        theme: theme,
                      ),
                      _settingsTile(
                        icon: Icons.two_wheeler_outlined,
                        title: "My Bikes",
                        subtitle: "Add or edit bikes",
                        theme: theme,
                      ),
                      _settingsTile(
                        icon: Icons.shield_outlined,
                        title: "Privacy",
                        subtitle: "Data & security",
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(
                          Icons.workspace_premium,
                          color: theme.primary,
                        ),
                        title: Text(
                          "Subscription",
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "Manage your subscription plan",
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.6),
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
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
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
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppThemeConfig theme,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.primary),
      title: Text(
        title,
        style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.textPrimary.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.textPrimary.withValues(alpha: 0.3),
        size: 20,
      ),
    );
  }
}
