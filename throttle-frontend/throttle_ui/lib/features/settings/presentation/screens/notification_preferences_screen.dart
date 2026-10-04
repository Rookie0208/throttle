import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/widgets/app_list_group.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/features/notifications/presentation/screens/notification_screen.dart';
import 'package:throttle_ui/features/settings/data/controllers/settings_preferences_controller.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  SettingsPreferencesController get _prefs =>
      SettingsPreferencesController.instance;

  @override
  void initState() {
    super.initState();
    _prefs.load();
  }

  Future<void> _openInbox() async {
    final token = await AuthService.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to view alerts.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          onClose: () => Navigator.pop(context),
          token: token,
        ),
      ),
    );
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
              'Notifications',
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
                _introCard(
                  theme,
                  title: 'Alert controls',
                  description:
                      'Choose which updates reach you, and open the notification inbox when you want the full feed.',
                ),
                const SizedBox(height: 16),
                _section(
                  theme,
                  title: 'Delivery',
                  children: [
                    _toggleTile(
                      theme: theme,
                      title: 'Enable notifications',
                      subtitle: 'Turn ride, social, and app alerts on or off.',
                      value: _prefs.notificationsEnabled,
                      onChanged: _prefs.setNotificationsEnabled,
                    ),
                    _toggleTile(
                      theme: theme,
                      title: 'Ride alerts',
                      subtitle: 'Invites, reminders, and pre-ride updates.',
                      value: _prefs.rideAlerts && _prefs.notificationsEnabled,
                      enabled: _prefs.notificationsEnabled,
                      onChanged: _prefs.setRideAlerts,
                    ),
                    _toggleTile(
                      theme: theme,
                      title: 'Friend requests',
                      subtitle: 'Requests, accepts, and connection updates.',
                      value:
                          _prefs.friendRequestAlerts &&
                          _prefs.notificationsEnabled,
                      enabled: _prefs.notificationsEnabled,
                      onChanged: _prefs.setFriendRequestAlerts,
                    ),
                    _toggleTile(
                      theme: theme,
                      title: 'Product updates',
                      subtitle: 'Occasional news, releases, and plan offers.',
                      value:
                          _prefs.marketingAlerts && _prefs.notificationsEnabled,
                      enabled: _prefs.notificationsEnabled,
                      onChanged: _prefs.setMarketingAlerts,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openInbox,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Open Notification Inbox'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
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

  Widget _introCard(
    AppThemeConfig theme, {
    required String title,
    required String description,
  }) {
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

  Widget _section(
    AppThemeConfig theme, {
    required String title,
    required List<Widget> children,
  }) {
    return AppListGroup(
      dividerIndent: 16,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Text(
          title,
          style: GoogleFonts.lexend(
            color: theme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      children: children,
    );
  }

  Widget _toggleTile({
    required AppThemeConfig theme,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: Colors.white,
      activeTrackColor: theme.primary,
      title: Text(
        title,
        style: TextStyle(
          color: enabled
              ? theme.textPrimary
              : theme.textPrimary.withValues(alpha: 0.45),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled
              ? theme.textPrimary.withValues(alpha: 0.65)
              : theme.textPrimary.withValues(alpha: 0.35),
          fontSize: 12,
        ),
      ),
    );
  }
}
