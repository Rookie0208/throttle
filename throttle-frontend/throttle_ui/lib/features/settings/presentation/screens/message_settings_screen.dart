import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/settings/data/controllers/settings_preferences_controller.dart';

class MessageSettingsScreen extends StatefulWidget {
  const MessageSettingsScreen({super.key});

  @override
  State<MessageSettingsScreen> createState() => _MessageSettingsScreenState();
}

class _MessageSettingsScreenState extends State<MessageSettingsScreen> {
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
              'Messages',
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
                _card(
                  theme,
                  title: 'Chat preferences',
                  description:
                      'These settings shape how your direct messaging experience feels inside the app.',
                ),
                const SizedBox(height: 16),
                _toggleTile(
                  theme: theme,
                  title: 'Allow message requests',
                  subtitle:
                      'Let riders outside your connections start a conversation.',
                  value: _prefs.allowMessageRequests,
                  onChanged: _prefs.setAllowMessageRequests,
                ),
                _toggleTile(
                  theme: theme,
                  title: 'Show message previews',
                  subtitle:
                      'Display message snippets in notifications and inbox cards.',
                  value: _prefs.showMessagePreviews,
                  onChanged: _prefs.setShowMessagePreviews,
                ),
                _toggleTile(
                  theme: theme,
                  title: 'Send read receipts',
                  subtitle:
                      'Let others know when you have opened a message thread.',
                  value: _prefs.sendReadReceipts,
                  onChanged: _prefs.setSendReadReceipts,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _card(
    AppThemeConfig theme, {
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x52B8C6DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x52B8C6DA)),
      ),
      child: SwitchListTile(
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
      ),
    );
  }
}
