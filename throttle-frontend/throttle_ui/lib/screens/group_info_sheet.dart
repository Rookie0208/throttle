import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/public_profile_screen.dart';
import 'package:throttle_ui/services/group_service.dart';
import 'package:throttle_ui/services/ride_member_service.dart';

class RideInfoScreen extends StatefulWidget {
  final Map<String, dynamic> rideGroup;
  final String token;

  const RideInfoScreen({
    super.key,
    required this.rideGroup,
    required this.token,
  });

  @override
  State<RideInfoScreen> createState() => _RideInfoScreenState();
}

class _RideInfoScreenState extends State<RideInfoScreen> {
  String searchQuery = "";

  Future<List<dynamic>> fetchMembers() async {
    final result = await GroupService.fetchRideMembers(
      widget.token,
      widget.rideGroup["uuid"],
    );

    return result["data"] ?? [];
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
                    widget.token, // <- use widget.token
                    widget.rideGroup["uuid"], // <- use widget.rideGroup
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
 
  void _editDescription() {
    TextEditingController controller =
        TextEditingController(text: widget.rideGroup["description"]);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1a1c20),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Description",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Enter group description",
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await GroupService.updateRide(
                    widget.token,
                    widget.rideGroup["uuid"],
                    {"description": controller.text},
                  );
                  Navigator.pop(context);
                  setState(() {
                    widget.rideGroup["description"] = controller.text;
                  });
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statTile(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xff1a1c20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xfffe6603)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _groupHeader() {
    final name = widget.rideGroup["title"] ?? "Ride";

    return Column(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xff1a1c20),
          child: Icon(
            Icons.directions_bike,
            size: 36,
            color: Color(0xfffe6603),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _statTile(Icons.route, widget.rideGroup["rideType"] ?? "Ride"),
        const SizedBox(width: 8),
        _statTile(Icons.map, widget.rideGroup["routeType"] ?? "Route"),
        const SizedBox(width: 8),
        _statTile(Icons.people,
            "${widget.rideGroup["maxRiders"] ?? 0} Riders"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.rideGroup["description"];
    final createdBy = widget.rideGroup["createdBy"] ?? "Captain";

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: const Text("Ride Info"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchMembers(),
        builder: (context, snapshot) {
          List members = snapshot.data ?? [];

          if (searchQuery.isNotEmpty) {
            members = members.where((m) {
              final name =
                  "${m["firstName"] ?? ""} ${m["lastName"] ?? ""}".toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _groupHeader(),
              _statsRow(),
              const SizedBox(height: 20),

              /// DESCRIPTION
              const Text(
                "Description",
                style: TextStyle(
                    color: Color(0xfffe6603), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _editDescription,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xff1a1c20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    description ?? "Add group description",
                    style: TextStyle(
                        color: description == null
                            ? Colors.white38
                            : Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Created by $createdBy",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),

              const SizedBox(height: 20),

              /// SETTINGS
              const Text(
                "Settings",
                style: TextStyle(
                    color: Color(0xfffe6603), fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text(
                  "Notifications",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              ListTile(
                title: const Text(
                  "Group Visibility",
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  widget.rideGroup["visibility"] ?? "PUBLIC",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 20),

              /// PARTICIPANTS HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${members.length} riders",
                    style: const TextStyle(
                        color: Color(0xfffe6603),
                        fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (_) {
                          TextEditingController controller =
                              TextEditingController();

                          return AlertDialog(
                            backgroundColor: const Color(0xff1a1c20),
                            title: const Text("Search Rider",
                                style: TextStyle(color: Colors.white)),
                            content: TextField(
                              controller: controller,
                              style: const TextStyle(color: Colors.white),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, controller.text),
                                child: const Text("Search"),
                              )
                            ],
                          );
                        },
                      );

                      if (result != null) {
                        setState(() {
                          searchQuery = result;
                        });
                      }
                    },
                  )
                ],
              ),

              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add, color: Color(0xfffe6603)),
                label: const Text(
                  "Add Members",
                  style: TextStyle(color: Color(0xfffe6603)),
                ),
              ),

              const SizedBox(height: 10),

              /// MEMBERS LIST
              if (!snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (members.isEmpty)
                const Text(
                  "No riders found",
                  style: TextStyle(color: Colors.white70),
                )
              else
                Column(
                  children: members.map((m) {
                    final member = Map<String, dynamic>.from(m);

                    final name =
                        "${member["firstName"] ?? ""} ${member["lastName"] ?? ""}"
                            .trim();

                    return ListTile(
                      onTap: () => _openMemberSheet(context, member),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xfffe6603),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "R",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        member["role"] ?? "",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 30),

              /// EXIT GROUP
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {},
                child: const Text("Exit Group", style: TextStyle(color: Colors.white)),
              )
            ],
          );
        },
      ),
    );
  }
}