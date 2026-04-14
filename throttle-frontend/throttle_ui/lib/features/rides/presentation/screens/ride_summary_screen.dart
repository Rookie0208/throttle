import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class RideSummaryScreen extends StatelessWidget {
  final String groupName;
  final Map<String, dynamic> session;

  const RideSummaryScreen({
    super.key,
    required this.groupName,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        final checkpoints = List<Map<String, dynamic>>.from(
          session["checkpoints"] ?? [],
        );
        final startTimeStr = session["startTime"];
        DateTime? startTime;
        if (startTimeStr != null) {
          try {
            startTime = DateTime.parse(startTimeStr);
          } catch (_) {}
        }
        final endTime = DateTime.now();
        final duration = startTime != null
            ? endTime.difference(startTime)
            : Duration.zero;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            title: Text(
              "Ride Summary",
              style: GoogleFonts.bebasNeue(color: theme.textPrimary),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  groupName,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Total Duration: ${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}",
                  style: TextStyle(color: theme.textPrimary),
                ),
                Text(
                  "Checkpoints Completed: ${checkpoints.length}",
                  style: TextStyle(color: theme.textPrimary),
                ),
                // Add more summary details as needed
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Home"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
