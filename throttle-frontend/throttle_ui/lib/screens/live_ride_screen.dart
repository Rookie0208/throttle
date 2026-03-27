import 'package:flutter/material.dart';
import 'package:throttle_ui/utils/app_colors.dart';

class LiveRideScreen extends StatelessWidget {
  final String groupName;
  final VoidCallback onEndRide;

  const LiveRideScreen({
    super.key,
    required this.groupName,
    required this.onEndRide,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text("$groupName - Live Ride"),
      ),
      body: Column(
        children: [

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text("Current Speed",
                    style: TextStyle(color: AppColors.textSecondary)),
                SizedBox(height: 6),
                Text("45 mph",
                    style: TextStyle(
                        fontSize: 32,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const Spacer(),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            onPressed: onEndRide,
            child: const Text("End Ride"),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}