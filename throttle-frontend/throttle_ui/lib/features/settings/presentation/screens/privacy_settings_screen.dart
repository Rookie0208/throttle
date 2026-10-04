import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/widgets/app_list_group.dart';
import 'package:throttle_ui/features/settings/data/controllers/settings_preferences_controller.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  SettingsPreferencesController get _prefs =>
      SettingsPreferencesController.instance;

  @override
  void initState() {
    super.initState();
    _prefs.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeController.instance, _prefs]),
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.textPrimary),
            title: Text(
              'Privacy',
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(theme),
                const SizedBox(height: 16),
                AppListGroup(
                  dividerIndent: 16,
                  children: [
                    _toggleTile(
                      theme: theme,
                      title: 'Private profile',
                      subtitle:
                          'Hide your profile details from riders who are not connected with you.',
                      value: _prefs.privateProfile,
                      onChanged: _prefs.setPrivateProfile,
                    ),
                    _toggleTile(
                      theme: theme,
                      title: 'Discoverable in search',
                      subtitle:
                          'Let other riders find you by rider ID or profile search.',
                      value: _prefs.discoverableProfile,
                      onChanged: _prefs.setDiscoverableProfile,
                    ),
                    _toggleTile(
                      theme: theme,
                      title: 'Share ride activity',
                      subtitle:
                          'Show recent rides and activity summaries on your profile.',
                      value: _prefs.shareRideActivity,
                      onChanged: _prefs.setShareRideActivity,
                    ),
                    _toggleTile(
                      theme: theme,
                      title: 'Show ride stats',
                      subtitle:
                          'Display totals like distance, streaks, and ride counts.',
                      value: _prefs.showRideStats,
                      onChanged: _prefs.setShowRideStats,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile visibility',
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'These controls are saved on-device right now and let you shape how visible your account feels across the app.',
            style: GoogleFonts.plusJakartaSans(
              color: theme.textPrimary.withValues(alpha: 0.7),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required AppThemeConfig theme,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: theme.primary,
      title: Text(
        title,
        style: TextStyle(
          color: theme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.textPrimary.withValues(alpha: 0.65),
          fontSize: 12,
        ),
      ),
    );
  }
}
