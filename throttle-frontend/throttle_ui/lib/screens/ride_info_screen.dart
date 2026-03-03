import 'package:flutter/material.dart';

class RideInfoScreen extends StatefulWidget {
  final Map<String, dynamic> rideGroup;
  final String userRole;
  final String userId;

  const RideInfoScreen({
    super.key,
    required this.rideGroup,
    required this.userRole,
    required this.userId,
  });

  @override
  State<RideInfoScreen> createState() => _RideInfoScreenState();
}

class _RideInfoScreenState extends State<RideInfoScreen> {
  late List<Map<String, dynamic>> members;

  @override
  void initState() {
    super.initState();
    members = List<Map<String, dynamic>>.from(widget.rideGroup["members"]);
  }

  @override
  Widget build(BuildContext context) {
    final rideStatus = widget.rideGroup["rideStatus"];
    final isCaptain = widget.userRole == "CAPTAIN";
    final canEdit = isCaptain && rideStatus == "CREATED";

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: Text(
          widget.rideGroup["name"],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride Info
            Text(
              "Ride Status: $rideStatus",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            if (canEdit)
              ElevatedButton(
                onPressed: () {
                  // TODO: implement ride editing modal
                },
                child: const Text("Edit Ride Info"),
              ),
            const SizedBox(height: 20),
            const Text(
              "Team Members:",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
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
                        canEdit
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
                                    // TODO: call API to update role
                                  });
                                },
                              )
                            : Text(
                                member["role"],
                                style: const TextStyle(color: Colors.white38),
                              ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}