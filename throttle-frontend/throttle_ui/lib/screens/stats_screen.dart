import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/dashboard_screen.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts


class AppColors {
  static const primary = Color(0xfffe6603);
  static const background = Color(0xff0f1114);
  static const card = Color(0xff16181d);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const border = Colors.white12;
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String activeTab = "analytics";
  String timeRange = "weekly";

  // Dummy data
  final weeklyData = [
    {'day': 'Mon', 'miles': 32, 'speed': 48},
    {'day': 'Tue', 'miles': 0, 'speed': 0},
    {'day': 'Wed', 'miles': 45, 'speed': 52},
    {'day': 'Thu', 'miles': 18, 'speed': 38},
    {'day': 'Fri', 'miles': 65, 'speed': 56},
    {'day': 'Sat', 'miles': 88, 'speed': 62},
    {'day': 'Sun', 'miles': 0, 'speed': 0},
  ];

  final monthlyData = [
    {'week': 'W1', 'miles': 120},
    {'week': 'W2', 'miles': 185},
    {'week': 'W3', 'miles': 248},
    {'week': 'W4', 'miles': 310},
  ];

  final rideHistory = [
    {'date': 'Feb 13', 'name': 'Canyon Loop', 'miles': 68, 'time': '2h 15m'},
    {'date': 'Feb 11', 'name': 'Coastal Run', 'miles': 45, 'time': '1h 30m'},
    {'date': 'Feb 9', 'name': 'Mountain Pass', 'miles': 92, 'time': '3h 10m'},
  ];

  final badges = [
    {'name': 'Century Rider', 'desc': '100 miles in a day', 'earned': true},
    {'name': 'Speed Demon', 'desc': 'Hit 100+ mph', 'earned': true},
    {'name': 'Early Bird', 'desc': '5 rides before 7 AM', 'earned': true},
    {'name': 'Iron Streak', 'desc': '30-day streak', 'earned': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Stats & Progress", style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => activeTab = "analytics"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: activeTab == "analytics" ? AppColors.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "Analytics",
                            style: TextStyle(
                              color: activeTab == "analytics" ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => activeTab = "gamification"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: activeTab == "gamification" ? AppColors.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "Gamification",
                            style: TextStyle(
                              color: activeTab == "gamification" ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Analytics tab
            if (activeTab == "analytics") ...[
              // Time range
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: ["weekly", "monthly", "yearly"].map((range) {
                    final selected = range == timeRange;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => timeRange = range),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            range,
                            style: TextStyle(
                              color: selected ? AppColors.primary : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Summary cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statCard("Total Distance", "248 mi"),
                    _statCard("Avg Speed", "54 mph"),
                    _statCard("Top Speed", "98 mph"),
                    _statCard("Elevation Gain", "4,820 ft"),
                  ],
                ),
              ),

              // Speed trend chart placeholder
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text("Speed Trends Chart Here", style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),

              // Ride history
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ride History", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      children: rideHistory.map((ride) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.2),
                                child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ride['name'] as String, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                    Text(ride['date'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("${ride['miles']} mi", style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                  Text(ride['time'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Gamification tab
            if (activeTab == "gamification") ...[
              // Streak placeholder
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(child: Text("Streak / Challenges / Badges here", style: TextStyle(color: Colors.white70))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}