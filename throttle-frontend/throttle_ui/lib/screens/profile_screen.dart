import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/subscription_screen.dart';

import '../utils/string_extensions.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ProfileScreen({super.key, this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> get rideHistory =>
      widget.userData != null && widget.userData!['recentRides'] != null
      ? List<Map<String, dynamic>>.from(widget.userData!['recentRides'])
      : [];

  List<Map<String, dynamic>> get achievements =>
      widget.userData != null && widget.userData!['achievements'] != null
      ? List<Map<String, dynamic>>.from(widget.userData!['achievements'])
      : [];

  List<Map<String, dynamic>> get bikes =>
      widget.userData != null && widget.userData!['bikes'] != null
      ? List<Map<String, dynamic>>.from(widget.userData!['bikes'])
      : [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xff1a1c20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xfffe6603), size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff1a1c20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: const Color(0xfffe6603).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_bike, color: Color(0xfffe6603)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride["title"] ?? ride["name"] ?? "Ride",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  ride["date"]?.toString() ?? "",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${ride["miles"] ?? 0} mi",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ride["duration"] ?? ride["time"] ?? "",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(dynamic achievement) {
    String name = achievement is String
        ? achievement
        : (achievement["title"] ?? "Badge");
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xfffe6603).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xfffe6603).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: const Color(0xfffe6603), size: 24),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xff1a1c20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1c20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 64,
                                width: 64,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xfffe6603,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  widget.userData != null &&
                                          widget.userData!['firstName'] !=
                                              null &&
                                          widget
                                              .userData!['firstName']
                                              .isNotEmpty
                                      ? widget.userData!['firstName'][0]
                                                .toUpperCase() +
                                            (widget.userData!['lastName'] !=
                                                        null &&
                                                    widget
                                                        .userData!['lastName']
                                                        .isNotEmpty
                                                ? widget
                                                      .userData!['lastName'][0]
                                                      .toUpperCase()
                                                : '')
                                      : "RU",
                                  style: const TextStyle(
                                    color: Color(0xfffe6603),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xfffe6603),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userData != null
                                      ? "${(widget.userData!['firstName'] ?? '').toString().toCapitalized()} ${(widget.userData!['lastName'] ?? '').toString().toCapitalized()}"
                                            .trim()
                                      : "Guest User",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.userData?['bio'] ??
                                      "Weekend warrior. Canyon lover.",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bike Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1c20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xff1a1c20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_bike,
                              color: Color(0xfffe6603),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bikes.isNotEmpty
                                      ? "${bikes.first['year']} ${bikes.first['make']} ${bikes.first['model']}"
                                      : "No Bike Registered",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  bikes.isNotEmpty
                                      ? "${bikes.first['type']} · ${bikes.first['engineCc']}cc"
                                      : "Add your bike in settings",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),

                    // Stats Summary
                    Row(
                      children: [
                        _buildStatCard(
                          Icons.directions,
                          "${widget.userData != null ? (widget.userData!['totalMiles'] ?? 0) : 0}",
                          "Total Miles",
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          Icons.calendar_today,
                          "${widget.userData != null ? (widget.userData!['totalRides'] ?? 0) : 0}",
                          "Total Rides",
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          Icons.emoji_events,
                          "${achievements.length}",
                          "Badges",
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xfffe6603),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: "Overview"),
                        Tab(text: "Rides"),
                        Tab(text: "Settings"),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Overview Tab
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Achievements",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 80,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: achievements
                                        .map<Widget>(
                                          (a) => _buildAchievementCard(a),
                                        )
                                        .toList(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Recent Rides",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  children: rideHistory
                                      .map((r) => _buildRideCard(r))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),

                          // Rides Tab
                          ListView(
                            children: rideHistory
                                .map<Widget>((r) => _buildRideCard(r))
                                .toList(),
                          ),

                          // Settings Tab
                          SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.notifications,
                                    color: Colors.white,
                                  ),
                                  title: const Text(
                                    "Notifications",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: const Text(
                                    "Manage alerts",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.message,
                                    color: Colors.white,
                                  ),
                                  title: const Text(
                                    "Messages",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: const Text(
                                    "Chat settings",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.people,
                                    color: Colors.white,
                                  ),
                                  title: const Text(
                                    "Followers",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: const Text(
                                    "Manage connections",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.directions_bike,
                                    color: Colors.white,
                                  ),
                                  title: const Text(
                                    "My Bikes",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: const Text(
                                    "Add or edit bikes",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.shield,
                                    color: Colors.white,
                                  ),
                                  title: const Text(
                                    "Privacy",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: const Text(
                                    "Data & security",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                // Subscription Section
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(
                                    Icons.workspace_premium,
                                    color: Color(0xfffe6603),
                                  ),
                                  title: const Text(
                                    "Subscription",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: const Text(
                                    "Manage your subscription plan",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SubscriptionScreen(
                                            onClose: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xfffe6603),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(80, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text("Manage"),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.logout),
                                  label: const Text("Log Out"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xfffe6603),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
