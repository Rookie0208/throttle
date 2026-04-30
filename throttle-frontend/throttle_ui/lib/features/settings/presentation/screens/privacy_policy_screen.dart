import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final theme = themeController.theme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.textPrimary),
            title: Text(
              'Privacy Policy',
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
                _PolicySection(
                  theme: theme,
                  title: 'Overview',
                  body:
                      'Throttle uses your account, ride, device, and connection details to support rider identity, coordination, and safety features inside the app.',
                ),
                _PolicySection(
                  theme: theme,
                  title: 'Data We Store',
                  body:
                      'This can include your profile details, bikes, ride participation, emergency contacts, and medical information that you choose to add in settings.',
                ),
                _PolicySection(
                  theme: theme,
                  title: 'Why We Use It',
                  body:
                      'We use this data to personalize your profile, help riders coordinate rides, improve in-app communication, and support emergency response scenarios.',
                ),
                _PolicySection(
                  theme: theme,
                  title: 'Sharing & Safety',
                  body:
                      'Emergency and medical details should only be used for rider safety workflows. Sensitive information should be shared only with authorized app systems and responsible ride operations.',
                ),
                _PolicySection(
                  theme: theme,
                  title: 'Your Control',
                  body:
                      'You can update your profile, emergency contacts, and medical information from settings. Remove data you no longer want stored in the app.',
                ),
                _PolicySection(
                  theme: theme,
                  title: 'Note',
                  body:
                      'This screen is a starter in-app privacy policy. If you have legal or compliance requirements, replace this copy with your approved policy text or host the final document and link to it from here.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.theme,
    required this.title,
    required this.body,
  });

  final AppThemeConfig theme;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.plusJakartaSans(
              color: theme.textPrimary.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
