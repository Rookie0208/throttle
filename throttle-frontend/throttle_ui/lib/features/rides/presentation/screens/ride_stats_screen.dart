import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class RideStatsScreen extends StatelessWidget {
  final String groupName;
  final String distance;
  final String duration;

  const RideStatsScreen({
    super.key,
    required this.groupName,
    required this.distance,
    required this.duration,
  });

  Widget statTile(String title, String value, AppThemeConfig theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.bebasNeue(
              color: theme.primary,
              fontSize: 28,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.surface,
            elevation: 0,
            title: Text(
              "RIDE STATS",
              style: GoogleFonts.bebasNeue(
                color: theme.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
            iconTheme: IconThemeData(color: theme.textPrimary),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  groupName,
                  style: GoogleFonts.bebasNeue(
                    color: theme.textPrimary,
                    fontSize: 24,
                    letterSpacing: 1.1,
                  ),
                ),

                const SizedBox(height: 30),

                statTile("Distance", distance, theme),
                statTile("Duration", duration, theme),
              ],
            ),
          ),
        );
      },
    );
  }
}
