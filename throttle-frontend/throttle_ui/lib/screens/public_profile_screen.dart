import 'package:flutter/material.dart';
import 'package:throttle_ui/utils/app_colors.dart';

class PublicProfileScreen extends StatelessWidget {

  final Map<String, dynamic> user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {

    final String name =
        "${user["firstName"] ?? ""} ${user["lastName"] ?? ""}".trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Rider Profile"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// PROFILE CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [

                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    name.isNotEmpty ? name[0] : "R",
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        user["bio"] ?? "Motorcycle enthusiast",
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [

                          Text(
                            "${user["followersCount"] ?? 0} Followers",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            "${user["followingCount"] ?? 0} Following",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),

                        ],
                      )
                    ],
                  ),
                ),

                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text("Follow"),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// STATS
          Row(
            children: [

              _stat("Miles", "${user["totalMiles"] ?? 0}"),

              const SizedBox(width: 8),

              _stat("Rides", "${user["totalRides"] ?? 0}"),

              const SizedBox(width: 8),

              _stat("Badges", "${user["badges"] ?? 0}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [

            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}