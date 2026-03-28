import 'package:flutter/material.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

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

  Widget statTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Ride Stats"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(groupName,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 30),

            statTile("Distance", distance),
            const SizedBox(height: 10),
            statTile("Duration", duration),
          ],
        ),
      ),
    );
  }
}