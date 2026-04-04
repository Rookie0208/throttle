import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:throttle_ui/features/rides/presentation/screens/plan_ride_screen.dart';
import 'package:throttle_ui/features/rides/presentation/screens/public_rides_screen.dart';
import 'package:throttle_ui/features/groups/data/services/group_service.dart';
import 'group_chat_screen.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

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
    final startTime = DateTime.tryParse((ride["startTime"] ?? "").toString())?.toLocal();

    final isCompleted = rawStatus == "COMPLETED" || rawStatus == "ENDED";
    final isCancelled = rawStatus == "CANCELLED";
    final isInProgress = rawStatus == "IN_PROGRESS";
    final isExpiredPending = startTime != null &&
        startTime.isBefore(now) &&
        !isCompleted &&
        !isCancelled &&
        !isInProgress;

    final effectiveRideStatus = isExpiredPending ? "CANCELLED" : rawStatus;
    final sectionStatus =
        (isCompleted || isCancelled || isExpiredPending) ? "archive" : "active";

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
      "members": []
    };
  }

  Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.motorcycle,
          size: 70,
          color: AppColors.white30,
        ),
        const SizedBox(height: 20),

        const Text(
          "No rides yet",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          "Join a ride or create your own.",
          style: TextStyle(color: AppColors.textMuted),
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
);
              },
              child: const Text("Join Ride"),
            ),

            const SizedBox(width: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PlanRideScreen(token: widget.token)));
              },
              child: const Text("Create Ride", style: TextStyle(color: AppColors.white),),
            ),
          ],
        )
      ],
    ),
  );
}

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHiddenGroups().then((_) => fetchGroups());
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
    final Map<String, dynamic> result =
        await GroupService.fetchMyGroups(widget.token);

    if (result["data"] != null && result["data"].isNotEmpty) {
      List<Map<String, dynamic>> rides =
          List<Map<String, dynamic>>.from(result["data"]);

      List<Map<String, dynamic>> mappedGroups = rides
          .map(_normalizeRide)
          .where((group) =>
              !(group["membershipStatus"] == "EXITED" &&
                  hiddenExitedGroupUuids.contains(group["uuid"])))
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


  Widget _buildGroupCard(Map<String, dynamic> group) {
    final isExited = group["membershipStatus"] == "EXITED";

    return GestureDetector(
      onTap: isExited
          ? null
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              group: group, token: widget.token,
            ),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.white24),
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
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    group["name"][0],
                    style: const TextStyle(
                      color: AppColors.primary,
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
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isExited) ...[
                        const SizedBox(height: 4),
                        const Text(
                          "You are no longer a member of this group",
                          style: TextStyle(
                            color: AppColors.textMuted,
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
                    style: const TextStyle(color: AppColors.textHint),
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
                      child: const Text("Rejoin"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _hideExitedGroup(group["uuid"].toString()),
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
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Separate active and completed groups
   // If no rides exist
if (groups.isEmpty) {
  return Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      title: const Text("Rides"),
    ),
    body: _buildEmptyState(),
  );
}

// Separate active and completed groups
final activeGroups = groups.where((g) => g["status"] == "active").toList();
final completedGroups = groups.where((g) => g["status"] == "archive").toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text("Rides"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.textSecondary,
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
              return _buildGroupCard(activeGroups[index]);
            },
          ),

          // Completed Groups Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: completedGroups.length,
            itemBuilder: (context, index) {
              return _buildGroupCard(completedGroups[index]);
            },
          ),
        ],
      ),
    );
  }
}
