import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/public_profile_screen.dart';
import 'package:throttle_ui/services/group_service.dart';
import 'package:throttle_ui/services/ride_member_service.dart';

class RideInfoScreen extends StatelessWidget {
  final Map<String, dynamic> rideGroup;
  final String token; // <-- you need to pass token from previous screen

  const RideInfoScreen({
    super.key,
    required this.rideGroup,
    required this.token,
  });

  // Fetch members from backend
  Future<List<dynamic>> fetchMembers() async {
    final result = await GroupService.fetchRideMembers(
      token,
      rideGroup["uuid"], // ride id
    );
    return result["data"] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    print("Ride Group Data: $rideGroup");
    final bool isActive = rideGroup["status"] == "active";

    // Backend fields
    final String title = rideGroup["title"] ?? "";
    final String description = rideGroup["description"] ?? "";
    final String routeType = rideGroup["routeType"] ?? "";
    final String rideType = rideGroup["rideType"] ?? "";
    final String startTime = rideGroup["startTime"] ?? "";
    final String endTime = rideGroup["endTime"] ?? "";
    final int maxRiders = rideGroup["maxRiders"] ?? 0;

    // locations
    List locations = rideGroup["locations"] ?? [];
    String startLocation = "";
    for (var loc in locations) {
      if (loc["locationType"] == "START") {
        startLocation = loc["name"] ?? "";
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: const Text("Ride Info"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HERO
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff1a1c20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isActive ? "Upcoming Ride" : "Completed Ride",
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xfffe6603)
                        : Colors.greenAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ========================
          // RIDE PLAN
          // ========================
          const Text(
            "Ride Plan",
            style: TextStyle(
              color: Color(0xfffe6603),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _metricTile("Ride Type", rideType),
          _metricTile("Route Type", routeType),
          _metricTile("Start Location", startLocation),
          _metricTile("Start Time", startTime),
          _metricTile("End Time", endTime),
          _metricTile("Max Riders", maxRiders == 0 ? "" : maxRiders.toString()),

          const SizedBox(height: 24),

          // ========================
          // PARTICIPANTS
          // ========================
          const Text(
            "Participants",
            style: TextStyle(
              color: Color(0xfffe6603),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Use FutureBuilder to load members dynamically
          FutureBuilder<List<dynamic>>(
            future: fetchMembers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(); // or CircularProgressIndicator()
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox(); // show empty if no members
              }

              List members = snapshot.data!;

              return Column(
                children: members.map((m) {
                  final member = Map<String, dynamic>.from(m);

                  final name =
                      "${member["firstName"] ?? ""} ${member["lastName"] ?? ""}"
                          .trim();

                  return GestureDetector(
                    onTap: () => _openMemberSheet(context, member),
                    child: _metricTile(name, member["role"] ?? ""),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openMemberSheet(BuildContext context, Map member) {
    // uncomment this when you have API ready for fetching roles
    //     Future<List<String>> fetchRoles() {
    //   return RideMemberService.fetchRoles(token);
    // }
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1a1c20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final String name =
            "${member["firstName"] ?? ""} ${member["lastName"] ?? ""}".trim();
        final String role = member["role"] ?? "MEMBER";

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// MEMBER BASIC INFO
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xfffe6603),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "U",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(role, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// VIEW PROFILE
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text(
                  "View Profile",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(
                        user: Map<String, dynamic>.from(member),
                      ),
                    ),
                  );
                  // Navigate to full profile screen
                },
              ),

              // uncomment this when you have API ready for fetching roles
              //               FutureBuilder<List<String>>(
              //   future: fetchRoles(),
              //   builder: (context, snapshot) {

              //     if (!snapshot.hasData) return const SizedBox();

              //     List<String> roles = snapshot.data!;

              //     return Column(
              //       children: roles.map((role) {

              //         return ListTile(
              //           leading: const Icon(Icons.shield, color: Colors.orange),
              //           title: Text(
              //             "Make this ${role.toLowerCase()}",
              //             style: const TextStyle(color: Colors.white),
              //           ),
              //           onTap: () async {

              //             await RideMemberService.updateRole(
              //               token,
              //               rideGroup["uuid"],
              //               member["userUuid"],
              //               role,
              //             );

              //             Navigator.pop(context);

              //             ScaffoldMessenger.of(context).showSnackBar(
              //               SnackBar(content: Text("Role updated to $role")),
              //             );
              //           },
              //         );

              //       }).toList(),
              //     );
              //   },
              // ),

              /// PROMOTE
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.green),
                title: const Text(
                  "Promote to Navigator",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // call promote API
                },
              ),

              /// DEMOTE
              ListTile(
                leading: const Icon(Icons.arrow_downward, color: Colors.orange),
                title: const Text(
                  "Demote to Member",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // call demote API
                },
              ),

              /// REMOVE
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text(
                  "Remove from Ride",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  await RideMemberService.removeMember(
                    token,
                    rideGroup["uuid"],
                    member["userUuid"],
                  );

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Member removed from ride")),
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _metricTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff1a1c20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
