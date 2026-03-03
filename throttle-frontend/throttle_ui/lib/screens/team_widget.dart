import 'package:flutter/material.dart';

class TeamWidget extends StatefulWidget {
  final Map<String, dynamic> group;
  final String userRole;

  const TeamWidget({super.key, required this.group, required this.userRole});

  @override
  State<TeamWidget> createState() => _TeamWidgetState();
}

class _TeamWidgetState extends State<TeamWidget> {
  late List<Map<String, dynamic>> members;

  @override
  void initState() {
    super.initState();
    members = List<Map<String, dynamic>>.from(widget.group["members"]);
  }

  @override
  Widget build(BuildContext context) {
    if (!["CAPTAIN", "NAVIGATOR"].contains(widget.userRole)) {
      return const Center(
        child: Text(
          "You don’t have permission to view this tab",
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final isEditable = widget.userRole == "CAPTAIN" && widget.group["rideStatus"] == "CREATED";

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xff1a1c20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(member["name"], style: const TextStyle(color: Colors.white)),
              isEditable
                  ? DropdownButton<String>(
                      value: member["role"],
                      dropdownColor: const Color(0xff0f1114),
                      items: ["RIDER", "NAVIGATOR", "TEAM_LEAD", "CAPTAIN"]
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          member["role"] = value!;
                          // Call API to update role
                        });
                      },
                    )
                  : Text(member["role"], style: const TextStyle(color: Colors.white38)),
            ],
          ),
        );
      },
    );
  }
}