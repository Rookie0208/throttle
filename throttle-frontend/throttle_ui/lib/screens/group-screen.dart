import 'package:flutter/material.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  String view = "list"; // list | detail | create
  Map<String, dynamic>? selectedGroup;
  String detailTab = "members"; // members | rides | leaderboard | stats

  final List<Map<String, dynamic>> publicGroups = [
    {"id": 1, "name": "Iron Riders", "members": 48, "rides": 12, "avatar": "IR"},
    {"id": 2, "name": "Canyon Cruisers", "members": 32, "rides": 8, "avatar": "CC"},
    {"id": 3, "name": "Night Owls MC", "members": 21, "rides": 15, "avatar": "NO"},
  ];

  final List<Map<String, dynamic>> privateGroups = [
    {"id": 4, "name": "Weekend Warriors", "members": 12, "rides": 6, "avatar": "WW"},
    {"id": 5, "name": "Sportbike Squad", "members": 8, "rides": 4, "avatar": "SS"},
  ];

  Widget _buildGroupCard(Map<String, dynamic> group, bool isPublic) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGroup = group;
          view = "detail";
          detailTab = "members";
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xff1a1c20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isPublic ? const Color(0xfffe6603).withOpacity(0.1) : const Color(0xff1a1c20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                group["avatar"],
                style: const TextStyle(
                  color: Color(0xfffe6603),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group["name"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text("${group["members"]} members · ${group["rides"]} rides/mo",
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            isPublic
                ? const Icon(Icons.chevron_right, color: Colors.white70)
                : const Icon(Icons.lock, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTabContent() {
    if (selectedGroup == null) return const SizedBox();

    switch (detailTab) {
      case "members":
        final members = ["Mike T.", "Sarah K.", "Jordan P.", "Alex R.", "Chris M."];
        return Column(
          children: members.asMap().entries.map((entry) {
            int i = entry.key;
            String name = entry.value;
            bool isAdmin = i == 0;
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xff1a1c20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24)),
              child: Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xff1a1c20),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      name.split(" ").map((n) => n[0]).join(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        Text(isAdmin ? "Admin" : "Member",
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    const Icon(Icons.emoji_events, color: Color(0xfffe6603))
                ],
              ),
            );
          }).toList(),
        );
      case "rides":
        final rides = ["Sunday Mountain Run", "Coastal Sunset Ride", "Highway 66 Sprint"];
        return Column(
          children: rides
              .map((ride) => Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xff1a1c20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xfffe6603)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ride, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              const Text("Feb 15, 2026 at 8:00 AM",
                                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70)
                      ],
                    ),
                  ))
              .toList(),
        );
      case "leaderboard":
        final leaderboard = [
          {"name": "Mike T.", "miles": 1240},
          {"name": "Alex R.", "miles": 980},
          {"name": "Jordan P.", "miles": 870},
          {"name": "Sarah K.", "miles": 650},
          {"name": "Chris M.", "miles": 420},
        ];
        return Column(
          children: leaderboard.asMap().entries.map((entry) {
            int i = entry.key;
            var rider = entry.value;
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xff1a1c20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24)),
              child: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: i == 0 ? const Color(0xfffe6603) : const Color(0xff1a1c20),
                        borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      "${i + 1}",
                      style: TextStyle(
                          color: i == 0 ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(rider["name"] as String, style: const TextStyle(color: Colors.white))),
                  Text("${rider["miles"]} mi",
                      style: const TextStyle(color: Colors.white, fontFamily: "monospace"))
                ],
              ),
            );
          }).toList(),
        );
      case "stats":
        final stats = [
          {"label": "Total Rides", "value": "42"},
          {"label": "Total Miles", "value": "4,160"},
          {"label": "Avg per Ride", "value": "99 mi"},
          {"label": "Active Members", "value": "38"},
        ];
        return GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: stats
              .map((stat) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xff1a1c20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(stat["value"] ?? "",
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontFamily: "monospace")),
                        const SizedBox(height: 4),
                        Text(stat["label"] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ))
              .toList(),
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (view == "detail" && selectedGroup != null) {
      return Scaffold(
        backgroundColor: const Color(0xff0f1114),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            view = "list";
                            selectedGroup = null;
                          });
                        },
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xff1a1c20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(selectedGroup!["name"],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),

                // Detail Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ["members", "rides", "leaderboard", "stats"].map((tab) {
                      bool active = detailTab == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => detailTab = tab),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color: active ? const Color(0xfffe6603) : const Color(0xff1a1c20),
                                borderRadius: BorderRadius.circular(16)),
                            child: Text(tab,
                                style: TextStyle(
                                    color: active ? Colors.white : Colors.white70,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Tab Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDetailTabContent(),
                ),

                // Chat Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message),
                    label: const Text("Open Group Chat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1a1c20),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    // List view
    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Groups & Clubs",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                    GestureDetector(
                      onTap: () {
                        setState(() => view = "create");
                      },
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xfffe6603),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),

              // Public Groups
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("Public Groups", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
              Column(
                  children: publicGroups.map((g) => _buildGroupCard(g, true)).toList()),

              // Private Groups
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("Private Groups", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
              Column(
                  children: privateGroups.map((g) => _buildGroupCard(g, false)).toList()),
            ],
          ),
        ),
      ),
    );
  }
}
