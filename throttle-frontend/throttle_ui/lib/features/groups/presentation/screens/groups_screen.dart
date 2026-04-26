import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:throttle_ui/features/rides/presentation/screens/plan_ride_screen.dart';
import 'package:throttle_ui/features/rides/presentation/screens/public_rides_screen.dart';
import 'package:throttle_ui/features/groups/data/services/group_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_refresh_notifier.dart';
import 'group_chat_screen.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class GroupsScreen extends StatefulWidget {
  final String token;

  const GroupsScreen({super.key, required this.token});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> groups = [];
  bool isLoading = true;
  late TabController _tabController;
  Set<String> hiddenExitedGroupUuids = <String>{};

  static const String _hiddenGroupsKey = 'hidden_exited_group_uuids';

  Map<String, dynamic> _normalizeRide(Map<String, dynamic> ride) {
    final now = DateTime.now();
    final rawStatus = (ride["status"] ?? "UNKNOWN").toString();
    final startTime = DateTime.tryParse(
      (ride["startTime"] ?? "").toString(),
    )?.toLocal();

    final isCompleted = rawStatus == "COMPLETED" || rawStatus == "ENDED";
    final isCancelled = rawStatus == "CANCELLED";
    final isInProgress = rawStatus == "IN_PROGRESS";
    final isExpiredPending =
        startTime != null &&
        startTime.isBefore(now) &&
        !isCompleted &&
        !isCancelled &&
        !isInProgress;

    final effectiveRideStatus = isExpiredPending ? "CANCELLED" : rawStatus;
    final sectionStatus = (isCompleted || isCancelled || isExpiredPending)
        ? "archive"
        : "active";

    return {
      ...ride,
      "id": ride["uuid"],
      "rideUuid": ride["uuid"],
      "uuid": ride["groupUuid"] ?? ride["uuid"],
      "name": ride["title"],
      "rideStatus": effectiveRideStatus,
      "status": sectionStatus,
      "myRole": ride["myRole"],
      "membershipStatus": ride["membershipStatus"] ?? "CREATED",
      "isMember": ride["isMember"] ?? true,
      "members": [],
    };
  }

  Widget _buildEmptyState(AppThemeConfig theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.motorcycle,
            size: 70,
            color: theme.textPrimary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          Text(
            "No rides yet",
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Join a ride or create your own.",
            style: GoogleFonts.plusJakartaSans(
              color: theme.textPrimary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicRidesScreen(token: widget.token),
                    ),
                  ).then((_) => fetchGroups());
                },
                style: TextButton.styleFrom(foregroundColor: theme.primary),
                child: const Text("Join Ride"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanRideScreen(token: widget.token),
                    ),
                  ).then((_) => fetchGroups());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Create Ride"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    RideRefreshNotifier.revision.addListener(_handleRideRefresh);
    _loadHiddenGroups().then((_) => fetchGroups());
  }

  @override
  void dispose() {
    RideRefreshNotifier.revision.removeListener(_handleRideRefresh);
    _tabController.dispose();
    super.dispose();
  }

  void _handleRideRefresh() {
    if (!mounted) return;
    fetchGroups();
  }

  Future<void> _loadHiddenGroups() async {
    final prefs = await SharedPreferences.getInstance();
    hiddenExitedGroupUuids =
        (prefs.getStringList(_hiddenGroupsKey) ?? <String>[]).toSet();
  }

  Future<void> _hideExitedGroup(String groupUuid) async {
    final prefs = await SharedPreferences.getInstance();
    hiddenExitedGroupUuids = {...hiddenExitedGroupUuids, groupUuid};
    await prefs.setStringList(
      _hiddenGroupsKey,
      hiddenExitedGroupUuids.toList(),
    );
    if (!mounted) return;
    setState(() {
      groups.removeWhere((group) => group["uuid"] == groupUuid);
    });
  }

  Future<void> fetchGroups() async {
    try {
      final Map<String, dynamic> result = await GroupService.fetchMyGroups(
        widget.token,
      );

      if (result["data"] != null && result["data"].isNotEmpty) {
        List<Map<String, dynamic>> rides = List<Map<String, dynamic>>.from(
          result["data"],
        );

        List<Map<String, dynamic>> mappedGroups = rides
            .map(_normalizeRide)
            .where(
              (group) =>
                  !(group["membershipStatus"] == "EXITED" &&
                      hiddenExitedGroupUuids.contains(group["uuid"])),
            )
            .toList();

        setState(() {
          groups = mappedGroups;
          isLoading = false;
        });
      } else {
        setState(() {
          groups = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        groups = [];
        isLoading = false;
      });
    }
  }

  Widget _buildGroupCard(Map<String, dynamic> group, AppThemeConfig theme) {
    final isExited = group["membershipStatus"] == "EXITED";

    return GestureDetector(
      onTap: isExited
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GroupChatScreen(group: group, token: widget.token),
                ),
              ).then((result) {
                if (result == true) {
                  fetchGroups();
                }
              });
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x52B8C6DA)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 45,
                  width: 45,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    group["name"][0],
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group["name"],
                        style: GoogleFonts.lexend(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isExited) ...[
                        const SizedBox(height: 4),
                        Text(
                          "You are no longer a member of this group",
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isExited)
                  Text(
                    group["rideStatus"],
                    style: GoogleFonts.lexend(
                      color: theme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            if (isExited) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          await GroupService.joinRide(
                            widget.token,
                            group["rideUuid"].toString(),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Rejoined ride")),
                          );
                          RideRefreshNotifier.notify();
                          await fetchGroups();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceFirst("Exception: ", ""),
                              ),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.primary),
                        foregroundColor: theme.primary,
                      ),
                      child: const Text("Rejoin"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          _hideExitedGroup(group["uuid"].toString()),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.textPrimary.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      child: const Text("Delete"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;

        if (isLoading) {
          return Scaffold(
            backgroundColor: theme.background,
            body: Center(
              child: CircularProgressIndicator(color: theme.primary),
            ),
          );
        }

        // Separate active and completed groups
        if (groups.isEmpty) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              backgroundColor: theme.background,
              title: Text(
                "Rides",
                style: GoogleFonts.lexend(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: _buildEmptyState(theme),
          );
        }

        final activeGroups = groups
            .where((g) => g["status"] == "active")
            .toList();
        final completedGroups = groups
            .where((g) => g["status"] == "archive")
            .toList();

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            title: Text(
              "Rides",
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: theme.primary,
              unselectedLabelColor: theme.textPrimary.withValues(alpha: 0.6),
              indicator: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: "Active"),
                Tab(text: "Completed"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Active Groups Tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeGroups.length,
                itemBuilder: (context, index) {
                  return _buildGroupCard(activeGroups[index], theme);
                },
              ),
              // Completed Groups Tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: completedGroups.length,
                itemBuilder: (context, index) {
                  return _buildGroupCard(completedGroups[index], theme);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
