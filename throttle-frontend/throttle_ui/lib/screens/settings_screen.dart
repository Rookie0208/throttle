import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/subscription_screen.dart';
import 'package:throttle_ui/services/auth_service.dart';
import 'package:throttle_ui/screens/onboarding_screen.dart';
import 'package:throttle_ui/utils/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
