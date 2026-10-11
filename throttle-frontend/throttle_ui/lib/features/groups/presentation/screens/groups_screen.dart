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
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> groups = [];
  bool isLoading = true;
  late TabController _tabController;
  int _selectedTab = 0;
  String _searchQuery = "";
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

  void _openPublicRides() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicRidesScreen(token: widget.token),
      ),
    ).then((_) => fetchGroups());
  }

  void _openPlanRide() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanRideScreen(token: widget.token),
      ),
    ).then((_) => fetchGroups());
  }

  Widget _emptyCard(
    AppThemeConfig theme, {
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.two_wheeler_outlined,
              size: 40,
              color: theme.textPrimary.withValues(alpha: 0.28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textPrimary.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(AppThemeConfig theme, String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.lexend(
            color: theme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.55),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _tabController.index != _selectedTab) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
    RideRefreshNotifier.revision.addListener(_handleRideRefresh);
    _loadHiddenGroups().then((_) => fetchGroups());
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    final groupName = (group["name"] ?? "Ride").toString();
    final firstChar = groupName.isNotEmpty ? groupName[0].toUpperCase() : "R";
    final status = (group["rideStatus"] ?? "").toString();

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
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: 0.06),
          ),
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
                    firstChar,
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: GoogleFonts.lexend(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
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
                if (!isExited && status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.lexend(
                        color: theme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

        final activeGroups = groups
            .where((g) => g["status"] == "active")
            .toList();
        final completedGroups = groups
            .where((g) => g["status"] == "archive")
            .toList();

        final filteredActive = activeGroups.where((g) {
          if (_searchQuery.isEmpty) return true;
          final name = (g["name"] ?? "").toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        final filteredCompleted = completedGroups.where((g) {
          if (_searchQuery.isEmpty) return true;
          final name = (g["name"] ?? "").toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        final currentList =
            _selectedTab == 0 ? filteredActive : filteredCompleted;

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: fetchGroups,
              color: theme.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                children: [
                  // Top Hero Card (similar to clubs page)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primary.withValues(alpha: 0.18),
                          theme.secondary.withValues(alpha: 0.12),
                          theme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.textPrimary.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Rides',
                                style: GoogleFonts.lexend(
                                  color: theme.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _openPublicRides,
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.primary,
                                foregroundColor:
                                    theme.brightness == Brightness.dark
                                        ? Colors.black
                                        : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.public_rounded, size: 18),
                              label: const Text('Public Rides'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Track your journeys, coordinate group adventures, and discover open rides.',
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.72),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim().toLowerCase();
                            });
                          },
                          style: TextStyle(color: theme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search rides',
                            hintStyle: TextStyle(
                              color: theme.textPrimary.withValues(alpha: 0.42),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: theme.primary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: 18,
                                      color: theme.textPrimary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: theme.background.withValues(alpha: 0.88),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: theme.textPrimary.withValues(
                                  alpha: 0.06,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: theme.textPrimary.withValues(
                                  alpha: 0.06,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Section Title: "Your Rides"
                  _sectionTitle(
                    theme,
                    'Your Rides',
                    '${activeGroups.length + completedGroups.length} total',
                  ),

                  const SizedBox(height: 12),

                  // Two Sub-Navigation Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.textPrimary.withValues(alpha: 0.06),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      onTap: (index) {
                        setState(() {
                          _selectedTab = index;
                        });
                      },
                      labelColor: theme.primary,
                      unselectedLabelColor:
                          theme.textPrimary.withValues(alpha: 0.6),
                      indicator: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Text(
                            "Active (${activeGroups.length})",
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            "Completed (${completedGroups.length})",
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Rides List or Empty State
                  if (currentList.isNotEmpty)
                    ...currentList.map((group) => _buildGroupCard(group, theme))
                  else if (_searchQuery.isNotEmpty)
                    _emptyCard(
                      theme,
                      title: "No rides found",
                      subtitle:
                          "No ${_selectedTab == 0 ? 'active' : 'completed'} rides match '$_searchQuery'.",
                    )
                  else if (_selectedTab == 0)
                    _emptyCard(
                      theme,
                      title: "No active rides",
                      subtitle:
                          "You don't have any upcoming or ongoing rides right now.",
                      action: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _openPublicRides,
                            icon: const Icon(Icons.public_rounded, size: 16),
                            label: const Text("Join Ride"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.primary,
                              side: BorderSide(color: theme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _openPlanRide,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Create Ride"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor:
                                  theme.brightness == Brightness.dark
                                      ? Colors.black
                                      : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _emptyCard(
                      theme,
                      title: "No completed rides",
                      subtitle:
                          "Completed rides and past journeys will appear here once finished.",
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
