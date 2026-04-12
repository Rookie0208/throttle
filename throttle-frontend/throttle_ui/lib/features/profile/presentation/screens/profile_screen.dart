import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/features/profile/presentation/screens/stats_screen.dart';
import 'package:throttle_ui/features/settings/presentation/screens/settings_screen.dart';

import 'package:throttle_ui/core/utils/string_extensions.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/rides/presentation/screens/ride_stats_screen.dart';

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

  Future<void> _editBio(AppThemeConfig theme) async {
    final TextEditingController bioController = TextEditingController(
      text: widget.userData?['bio'] ?? "",
    );

    bool? saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text("Edit Bio", style: TextStyle(color: theme.textPrimary)),
        content: TextField(
          controller: bioController,
          style: TextStyle(color: theme.textPrimary),
          maxLength: 150,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Tell us about your riding style...",
            hintStyle: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.4),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.textPrimary.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xff697389)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
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

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    AppThemeConfig theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.primary, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.bebasNeue(
            color: theme.textPrimary,
            fontSize: 18,
            letterSpacing: 1.1,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.65),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride, AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x52B8C6DA)),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.directions_bike, color: theme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride["title"] ?? ride["name"] ?? "Ride",
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  ride["date"]?.toString() ?? "",
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${ride["miles"] ?? 0} mi",
                style: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ride["duration"] ?? ride["time"] ?? "",
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(dynamic achievement, AppThemeConfig theme) {
    String name = achievement is String
        ? achievement
        : (achievement["title"] ?? "Badge");
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: theme.primary, size: 24),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              color: theme.textPrimary,
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
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Profile",
                        style: TextStyle(
                          color: theme.textPrimary,
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
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Icon(Icons.settings, color: theme.textPrimary),
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
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    height: 64,
                                    width: 64,
                                    decoration: BoxDecoration(
                                      color: theme.primary.withValues(
                                        alpha: 0.15,
                                      ),
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
                                      style: TextStyle(
                                        color: theme.primary,
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
                                        color: theme.primary,
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
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if ((widget.userData?['riderId'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          "@${widget.userData!['riderId']}",
                                          style: TextStyle(
                                            color: theme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    GestureDetector(
                                      onTap: () => _editBio(theme),
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
                                              style: TextStyle(
                                                color: theme.textPrimary
                                                    .withValues(alpha: 0.65),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.edit,
                                            color: theme.textPrimary.withValues(
                                              alpha: 0.4,
                                            ),
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
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: theme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.directions_bike,
                                  color: theme.primary,
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
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      bikes.isNotEmpty
                                          ? "${bikes.first['type']} · ${bikes.first['engineCc']}cc"
                                          : "Add your bike in settings",
                                      style: TextStyle(
                                        color: theme.textPrimary.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: theme.textPrimary.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),

                        // Consolidated Ride Stats Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "RIDE STATS",
                                style: GoogleFonts.bebasNeue(
                                  color: theme.textPrimary,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    Icons.directions,
                                    "${widget.userData?['totalMiles'] ?? 0}",
                                    "Miles",
                                    theme,
                                  ),
                                  _buildStatItem(
                                    Icons.calendar_today,
                                    "${widget.userData?['totalRides'] ?? 0}",
                                    "Rides",
                                    theme,
                                  ),
                                  _buildStatItem(
                                    Icons.emoji_events,
                                    "${achievements.length}",
                                    "Badges",
                                    theme,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StatsScreen(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: theme.primary.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    "SEE FULL RIDE STATS",
                                    style: GoogleFonts.bebasNeue(
                                      color: theme.primary,
                                      fontSize: 14,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tab Bar
                        TabBar(
                          controller: _tabController,
                          labelColor: theme.primary,
                          unselectedLabelColor: theme.textPrimary.withValues(
                            alpha: 0.6,
                          ),
                          indicatorColor: theme.primary,
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
                                    Text(
                                      "Achievements",
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: achievements.isEmpty ? null : 80,
                                      child: achievements.isEmpty
                                          ? Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 24,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: theme.surface,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(
                                                    0x52B8C6DA,
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.workspace_premium,
                                                    color: theme.textPrimary
                                                        .withValues(alpha: 0.1),
                                                    size: 32,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    "Complete rides to earn badges!",
                                                    style: TextStyle(
                                                      color: theme.textPrimary
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
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
                                                    (a) =>
                                                        _buildAchievementCard(
                                                          a,
                                                          theme,
                                                        ),
                                                  )
                                                  .toList(),
                                            ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Recent Rides",
                                      style: TextStyle(
                                        color: theme.textPrimary,
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
                                              color: theme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0x52B8C6DA),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.route,
                                                  color: theme.textPrimary
                                                      .withValues(alpha: 0.1),
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  "Your journey begins here",
                                                  style: TextStyle(
                                                    color: theme.textPrimary,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  "Start tracking your rides to see your history",
                                                  style: TextStyle(
                                                    color: theme.textPrimary
                                                        .withValues(alpha: 0.6),
                                                    fontSize: 13,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          )
                                        : Column(
                                            children: rideHistory
                                                .map(
                                                  (r) =>
                                                      _buildRideCard(r, theme),
                                                )
                                                .toList(),
                                          ),
                                  ],
                                ),
                              ),

                              // Rides Tab
                              rideHistory.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.history,
                                            color: theme.textPrimary.withValues(
                                              alpha: 0.1,
                                            ),
                                            size: 64,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "Your journey begins here",
                                            style: TextStyle(
                                              color: theme.textPrimary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Your completed rides will appear here.",
                                            style: TextStyle(
                                              color: theme.textPrimary
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView(
                                      children: rideHistory
                                          .map<Widget>(
                                            (r) => _buildRideCard(r, theme),
                                          )
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
      },
    );
  }
}
