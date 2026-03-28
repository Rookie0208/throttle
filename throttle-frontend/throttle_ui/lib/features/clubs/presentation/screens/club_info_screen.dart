import 'package:flutter/material.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

class ClubInfoScreen extends StatelessWidget {
  final Map<String, dynamic> club;

  const ClubInfoScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    final members = [
      "Mike T.",
      "Sarah K.",
      "Jordan P.",
      "Alex R.",
      "Chris M."
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Club Info"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ===============================
          // HERO SECTION
          // ===============================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club["name"],
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      "${club["members"]} members",
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Public Club",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Founded: Jan 2024",
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                )
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ===============================
          // PERFORMANCE STATS
          // ===============================
          const Text(
            "Performance Stats",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _statCard("Total Rides", "142"),
              _statCard("Total Distance", "18,420 km"),
              _statCard("Avg per Ride", "129 km"),
              _statCard("Longest Ride", "420 km"),
              _statCard("Active Riders", "38"),
              _statCard("Monthly Distance", "3,200 km"),
            ],
          ),

          const SizedBox(height: 24),

          // ===============================
          // COMPETITIVE METRICS
          // ===============================
          const Text(
            "Club Ranking",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _highlightCard("Global Rank", "#12"),
          _highlightCard("Monthly Rank", "#3"),
          _highlightCard("Activity Streak", "27 Days 🔥"),
          _highlightCard("Trophies Won", "8 🏆"),

          const SizedBox(height: 24),

          // ===============================
          // ENGAGEMENT HEALTH
          // ===============================
          const Text(
            "Engagement",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _highlightCard("Ride Participation", "78%"),
          _highlightCard("Member Growth", "+5 this month"),
          _highlightCard("Chat Activity", "140 msgs/week"),

          const SizedBox(height: 24),

          // ===============================
          // MEMBERS
          // ===============================
          const Text(
            "Members",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...members.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            final isCaptain = index == 0;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  if (isCaptain)
                    const Icon(Icons.emoji_events,
                        color: AppColors.primary, size: 18),
                  if (isCaptain) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  if (isCaptain)
                    const Text(
                      "Captain",
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}