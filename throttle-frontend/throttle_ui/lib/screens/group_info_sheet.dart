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

  Widget _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: $value",
        style: const TextStyle(color: Colors.white),
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
    TextEditingController controller = TextEditingController(
      text: widget.rideGroup["description"],
    );

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
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader() {
    final name = widget.rideGroup["title"] ?? "Ride";
    final creatorUser = widget.rideGroup["createdByUser"];
    final creatorName = creatorUser != null
        ? "${creatorUser["firstName"] ?? ""} ${creatorUser["lastName"] ?? ""}"
              .trim()
        : widget.rideGroup["createdByName"] ?? "Unknown";

    final createdAt = widget.rideGroup["createdAt"];

    final preRideInfo = widget.rideGroup["preRideInfo"] ?? {};

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
        const SizedBox(height: 6),
        if (creatorName.isNotEmpty || createdAt != null)
          Text(
            "${creatorName.isNotEmpty ? creatorName : "Unknown"}"
            "${createdAt != null ? " • ${formatTime(createdAt)}" : ""}",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        const SizedBox(height: 20),

        // Pre-Ride Info Card
        if (preRideInfo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              color: const Color(0xff1a1c20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pre-Ride Information",
                      style: TextStyle(
                        color: Color(0xfffe6603),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (preRideInfo["meetingPoint"] != null)
                      Text(
                        "📍 Meeting Point: ${preRideInfo["meetingPoint"]}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    if (preRideInfo["estimatedStops"] != null)
                      Text(
                        "🛑 Estimated Stops: ${preRideInfo["estimatedStops"]}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    if (preRideInfo["fuelStops"] != null)
                      Text(
                        "⛽ Fuel Stops: ${preRideInfo["fuelStops"]}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    if (preRideInfo["breakPoints"] != null)
                      Text(
                        "☕ Break Points: ${preRideInfo["breakPoints"]}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    if (preRideInfo["checkpoints"] != null)
                      Text(
                        "📌 Checkpoints: ${preRideInfo["checkpoints"]}",
                        style: const TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),
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
        _statTile(Icons.people, "${widget.rideGroup["maxRiders"] ?? 0} Riders"),
      ],
    );
  }

  String formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _openPreRideInfo() {
    final meetingPointController = TextEditingController();
    final stopsController = TextEditingController();
    final fuelStopsController = TextEditingController();
    final breakPointsController = TextEditingController();
    final checkpointsController = TextEditingController();
    final speedLimitController = TextEditingController();
    final emergencyContactController = TextEditingController();
    final rideRulesController = TextEditingController();
    final notesController = TextEditingController();

    final preRideInfo = widget.rideGroup["preRideInfo"] ?? {};

    meetingPointController.text = preRideInfo["meetingPoint"] ?? "";
    stopsController.text = preRideInfo["estimatedStops"] ?? "";
    fuelStopsController.text = preRideInfo["fuelStops"] ?? "";
    breakPointsController.text = preRideInfo["breakPoints"] ?? "";
    checkpointsController.text = preRideInfo["checkpoints"] ?? "";
    speedLimitController.text = preRideInfo["speedLimit"] ?? "";
    emergencyContactController.text = preRideInfo["emergencyContact"] ?? "";
    rideRulesController.text = preRideInfo["rideRules"] ?? "";
    notesController.text = preRideInfo["notes"] ?? "";

    // Disable input fields for normal users
    // bool isEditable = (widget.rideGroup["myRole"] == "CAPTAIN" || widget.rideGroup["myRole"] == "ADMIN");
    bool isEditable =
        true; // for now, only allow viewing pre-ride info. Editing can be implemented later.
    if (!isEditable) {
      // Disable text input fields for non-admin/captain users
      meetingPointController.text = preRideInfo["meetingPoint"] ?? "";
      stopsController.text = preRideInfo["estimatedStops"] ?? "";
      fuelStopsController.text = preRideInfo["fuelStops"] ?? "";
      breakPointsController.text = preRideInfo["breakPoints"] ?? "";
      checkpointsController.text = preRideInfo["checkpoints"] ?? "";
      speedLimitController.text = preRideInfo["speedLimit"] ?? "";
      emergencyContactController.text = preRideInfo["emergencyContact"] ?? "";
      rideRulesController.text = preRideInfo["rideRules"] ?? "";
      notesController.text = preRideInfo["notes"] ?? "";

      // Disable input fields
      meetingPointController.selection = TextSelection.collapsed(
        offset: meetingPointController.text.length,
      );
      stopsController.selection = TextSelection.collapsed(
        offset: stopsController.text.length,
      );
      fuelStopsController.selection = TextSelection.collapsed(
        offset: fuelStopsController.text.length,
      );
      breakPointsController.selection = TextSelection.collapsed(
        offset: breakPointsController.text.length,
      );
      checkpointsController.selection = TextSelection.collapsed(
        offset: checkpointsController.text.length,
      );
      speedLimitController.selection = TextSelection.collapsed(
        offset: speedLimitController.text.length,
      );
      emergencyContactController.selection = TextSelection.collapsed(
        offset: emergencyContactController.text.length,
      );
      rideRulesController.selection = TextSelection.collapsed(
        offset: rideRulesController.text.length,
      );
      notesController.selection = TextSelection.collapsed(
        offset: notesController.text.length,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1a1c20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Pre Ride Information",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _input("📍 Meeting Point", meetingPointController, isEditable),
                _input("🛑 Estimated Stops", stopsController, isEditable),
                _input("⛽ Fuel Stops", fuelStopsController, isEditable),
                _input("⏸️ Break Points", breakPointsController, isEditable),
                _input("🏁 Checkpoints", checkpointsController, isEditable),
                _input(" Speedway Limit", speedLimitController, isEditable),
                _input(
                  "Emergency Contact",
                  emergencyContactController,
                  isEditable,
                ),
                _input("Ride Rules", rideRulesController, isEditable),
                _input("Notes", notesController, isEditable),

                const SizedBox(height: 16),

                // Enable "Save & Notify" only for captain/admin
                if (isEditable)
                  ElevatedButton(
                    onPressed: () async {
                      // Capture inputs for pre-ride info
                      final preRideData = {
                        "meetingPoint": meetingPointController.text,
                        "estimatedStops": stopsController.text,
                        "fuelStops": fuelStopsController.text,
                        "breakPoints": breakPointsController.text,
                        "checkpoints": checkpointsController.text,
                        "speedLimit": speedLimitController.text,
                        "emergencyContact": emergencyContactController.text,
                        "rideRules": rideRulesController.text,
                        "notes": notesController.text,
                      };

                      // Call the update service
                      await GroupService.updatePreRideInfo(
                        widget.token,
                        widget.rideGroup["uuid"],
                        preRideData,
                      );

                      // Optionally: Show notification to participants
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pre-Ride Information updated!"),
                        ),
                      );

                      Navigator.pop(context);
                    },
                    child: const Text("Save & Notify"),
                  )
                else
                  const Text(
                    "You do not have permission to edit this information.",
                    style: TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper function to create input fields with disable logic
  Widget _input(
    String label,
    TextEditingController controller,
    bool isEditable,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        enabled: isEditable, // Enable or disable based on user role
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xff0f1114),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.rideGroup["description"];
    final creatorUser = widget.rideGroup["createdByUser"];
    final creatorName = creatorUser != null
        ? "${creatorUser["firstName"] ?? ""} ${creatorUser["lastName"] ?? ""}"
              .trim()
        : widget.rideGroup["createdByName"] ?? "Unknown";

    final createdAt = widget.rideGroup["createdAt"];
    final preRide = widget.rideGroup["preRideInfo"];

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: const Text("Group Info"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchMembers(),
        builder: (context, snapshot) {
          List members = snapshot.data ?? [];

          if (searchQuery.isNotEmpty) {
            members = members.where((m) {
              final name = "${m["firstName"] ?? ""} ${m["lastName"] ?? ""}"
                  .toLowerCase();
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
                  color: Color(0xfffe6603),
                  fontWeight: FontWeight.bold,
                ),
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
                          : Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: _openPreRideInfo,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xff1a1c20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xfffe6603)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Add Pre Ride Information",
                        style: TextStyle(color: Color(0xfffe6603)),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xfffe6603),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              if (preRide != null) ...[
                const SizedBox(height: 20),

                const Text(
                  "Pre Ride Plan",
                  style: TextStyle(
                    color: Color(0xfffe6603),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xff1a1c20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow("📍 Meeting Point", preRide["meetingPoint"]),
                      _infoRow("🛑 Stops", preRide["stops"]),
                      _infoRow("⛽ Fuel Stops", preRide["fuelStops"]),
                      _infoRow("☕ Break Points", preRide["breakPoints"]),
                      _infoRow("📍 Checkpoints", preRide["checkpoints"]),
                      _infoRow("🏥 Emergency", preRide["emergencyContact"]),

                      if (preRide["rules"] != null) ...[
                        const SizedBox(height: 10),
                        const Text(
                          "Rules",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preRide["rules"],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              /// SETTINGS
              const Text(
                "Settings",
                style: TextStyle(
                  color: Color(0xfffe6603),
                  fontWeight: FontWeight.bold,
                ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${members.length} riders",
                    style: const TextStyle(
                      color: Color(0xfffe6603),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  /// SEARCH BAR
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search riders...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white54,
                        ),
                        filled: true,
                        fillColor: const Color(0xff1a1c20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// ✅ ROUNDED ADD BUTTON
                  GestureDetector(
                    onTap: () {
                      // open add members
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xfffe6603),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add, color: Colors.white),
                    ),
                  ),
                ],
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
                onPressed: () {
                  final myRole = widget.rideGroup["myRole"];

                  if (myRole == "CAPTAIN") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Assign a new captain before leaving"),
                      ),
                    );
                    return;
                  }

                  // call exit API
                },
                child: const Text(
                  "Exit Group",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}