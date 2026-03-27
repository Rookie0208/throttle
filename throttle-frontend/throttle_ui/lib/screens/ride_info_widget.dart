import 'package:flutter/material.dart';
import 'package:throttle_ui/utils/app_colors.dart';

class RideInfoWidget extends StatelessWidget {
  final Map<String, dynamic> group;
  final String userRole;

  const RideInfoWidget({super.key, required this.group, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final rideStatus = group["rideStatus"];
    final isEditable = userRole == "CAPTAIN" && rideStatus == "CREATED";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Ride Status: $rideStatus", style: const TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text("Editable by you: ${isEditable ? "Yes" : "No"}", style: const TextStyle(color: AppColors.textHint)),
          const SizedBox(height: 20),
          isEditable
              ? ElevatedButton(
                  onPressed: () {
                    // Show edit ride modal
                  },
                  child: const Text("Edit Ride Info"),
                )
              : const SizedBox(),
        ],
      ),
    );
  }
}