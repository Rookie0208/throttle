
import 'package:flutter/material.dart';

class ManageMembersScreen extends StatelessWidget {

  final Map group;
  final String token;

  const ManageMembersScreen({super.key, required this.group, required this.token});

  @override
  Widget build(BuildContext context) {

    List members = group["members"] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        title: const Text("Manage Members"),
        backgroundColor: const Color(0xff1a1c20),
      ),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {

          var m = members[index];

          return ListTile(
            title: Text(m["name"], style: const TextStyle(color: Colors.white)),
            subtitle: Text(m["role"], style: const TextStyle(color: Colors.white70)),
            trailing: PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: "remove", child: Text("Remove")),
                const PopupMenuItem(value: "navigator", child: Text("Make Navigator")),
              ],
            ),
          );
        },
      ),
    );
  }
}