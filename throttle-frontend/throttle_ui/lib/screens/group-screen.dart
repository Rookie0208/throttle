import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/group_chat_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = [
      {
        "name": "Sunday Canyon Ride",
        "avatar": "SC",
        "status": "active",
        "members": 12,
        "distance": "120 km",
        "createdBy": "Vishal",
      },
      {
        "name": "Mountain Explorers",
        "avatar": "ME",
        "status": "archived",
        "members": 8,
        "distance": "95 km",
        "createdBy": "Rahul",
      },
    ];

    // Separate groups
    final activeGroups =
        groups.where((g) => g["status"] == "active").toList();
    final archivedGroups =
        groups.where((g) => g["status"] == "archived").toList();

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f1114),
        title: const Text("Rides"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active Section
          if (activeGroups.isNotEmpty) ...[
            const Text(
              "Active Groups",
              style: TextStyle(
                color: Color(0xfffe6603),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...activeGroups.map(
              (group) => _buildGroupCard(context, group),
            ),
            const SizedBox(height: 24),
          ],

          // Archived Section
          if (archivedGroups.isNotEmpty) ...[
            const Text(
              "Archived Groups",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...archivedGroups.map(
              (group) => _buildGroupCard(context, group),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupCard(
      BuildContext context, Map<String, dynamic> group) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(group: group),
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
                group["avatar"],
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
          ],
        ),
      ),
    );
  }
}