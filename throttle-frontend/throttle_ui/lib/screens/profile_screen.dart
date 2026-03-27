import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/settings_screen.dart';
import 'package:throttle_ui/screens/subscription_screen.dart';

import '../utils/string_extensions.dart';
import '../services/user_service.dart';
import 'package:throttle_ui/utils/app_colors.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _editBio() async {
    final TextEditingController bioController = TextEditingController(
      text: widget.userData?['bio'] ?? "",
    );

    bool? saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Edit Bio", style: TextStyle(color: AppColors.white)),
        content: TextField(
          controller: bioController,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLength: 150,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Tell us about your riding style...",
            hintStyle: TextStyle(color: AppColors.textHint),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Save", style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (saved == true && widget.userData != null && mounted) {
      final newBio = bioController.text.trim();
      final oldBio = widget.userData!['bio'];

      // Optimistic UI update
      setState(() {
        widget.userData!['bio'] = newBio;
      });

      // API Call
      bool success = await UserService.updateProfile({
        "bio": newBio,
        "firstName": widget.userData!['firstName'] ?? "",
        "lastName": widget.userData!['lastName'] ?? "",
        "profileImage": widget.userData!['profileImage'] ?? "",
      });

      if (!success && mounted) {
        // Rollback
        setState(() {
          widget.userData!['bio'] = oldBio;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save bio on the server.")),
        );
      }
    }
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white24),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white24),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_bike, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride["title"] ?? ride["name"] ?? "Ride",
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  ride["date"]?.toString() ?? "",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ride["duration"] ?? ride["time"] ?? "",
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: AppColors.primary, size: 24),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.white,
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
      backgroundColor: AppColors.background,
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
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings, color: AppColors.white),
                    ),
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.white24),
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
                                    color: AppColors.primary,
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
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: AppColors.white,
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
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: _editBio,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.userData?['bio'] != null &&
                                                  widget.userData!['bio']
                                                      .toString()
                                                      .isNotEmpty
                                              ? widget.userData!['bio']
                                              : "Tell us about your riding style...",
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.edit,
                                        color: AppColors.textHint,
                                        size: 14,
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

                    // Bike Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.white24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_bike,
                              color: AppColors.primary,
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
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  bikes.isNotEmpty
                                      ? "${bikes.first['type']} · ${bikes.first['engineCc']}cc"
                                      : "Add your bike in settings",
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
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
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: const [
                        Tab(text: "Overview"),
                        Tab(text: "Rides"),
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
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: achievements.isEmpty ? null : 80,
                                  child: achievements.isEmpty
                                      ? Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 24,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: AppColors.white12,
                                            ),
                                          ),
                                          child: Column(
                                            children: const [
                                              Icon(
                                                Icons.workspace_premium,
                                                color: AppColors.white24,
                                                size: 32,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                "Complete rides to earn badges!",
                                                style: TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView(
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
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                rideHistory.isEmpty
                                    ? Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 32,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.white12,
                                          ),
                                        ),
                                        child: Column(
                                          children: const [
                                            Icon(
                                              Icons.route,
                                              color: AppColors.white24,
                                              size: 48,
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              "Your journey begins here",
                                              style: TextStyle(
                                                color: AppColors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              "Start tracking your rides to see your history",
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 13,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        children: rideHistory
                                            .map((r) => _buildRideCard(r))
                                            .toList(),
                                      ),
                              ],
                            ),
                          ),

                          // Rides Tab
                          rideHistory.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.history,
                                        color: AppColors.white24,
                                        size: 64,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "Your journey begins here",
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Your completed rides will appear here.",
                                        style: TextStyle(color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView(
                                  children: rideHistory
                                      .map<Widget>((r) => _buildRideCard(r))
                                      .toList(),
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
