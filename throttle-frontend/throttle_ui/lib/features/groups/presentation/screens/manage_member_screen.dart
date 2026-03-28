
import 'package:flutter/material.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

class ManageMembersScreen extends StatelessWidget {

  final Map group;
  final String token;

  const ManageMembersScreen({super.key, required this.group, required this.token});

  @override
  Widget build(BuildContext context) {

    List members = group["members"] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Manage Members"),
        backgroundColor: AppColors.surface,
      ),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {

          var m = members[index];

          return ListTile(
            title: Text(m["name"], style: const TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(m["role"], style: const TextStyle(color: AppColors.textSecondary)),
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