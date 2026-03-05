import 'package:flutter/material.dart';
import 'group_chat_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    // Replace this with your real API call
    // final result = await GroupService.fetchMyGroups(widget.token);

    // Dummy data
    setState(() {
      groups = [
        {
          "id": "1",
          "name": "Morning Riders",
          "status": "active",
          "rideStatus": "CREATED",
          "members": [
            {"id": "u1", "name": "Amit", "role": "CAPTAIN"},
            {"id": "u2", "name": "Sara", "role": "RIDER"},
            {"id": "u3", "name": "John", "role": "NAVIGATOR"},
          ]
        },
        {
          "id": "2",
          "name": "Weekend Warriors",
          "status": "archive",
          "rideStatus": "STARTED",
          "members": [
            {"id": "u4", "name": "Lily", "role": "CAPTAIN"},
            {"id": "u5", "name": "Tom", "role": "RIDER"},
          ]
        },
      ];
      isLoading = false;
    });
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              group: group,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xff1a1c20),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Container(
              height: 45,
              width: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xfffe6603).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                group["name"][0], // first letter
                style: const TextStyle(
                  color: Color(0xfffe6603),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                group["name"],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              group["rideStatus"], // show ride status
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Separate active and completed groups
    final activeGroups = groups.where((g) => g["status"] == "active").toList();
    final completedGroups = groups.where((g) => g["status"] == "archive").toList();

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f1114),
        title: const Text("Rides"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xfffe6603),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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