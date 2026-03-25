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
    int step = 0;

    final meetingController = TextEditingController();
    final fuelController = TextEditingController();
    final checkpointController = TextEditingController();
    final notesController = TextEditingController();

    List<String> checkpoints = [];
    List<String> selectedRules = [];

    final rules = [
      "No overspeeding",
      "Stay in formation",
      "No reckless riding",
      "Follow captain",
      "Helmet mandatory",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1a1c20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget section;

            /// ---------- STEP 1 ----------
            if (step == 0) {
              section = SizedBox(
                height:
                    MediaQuery.of(context).size.height *
                    0.15, // slightly bigger
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Meeting Point",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: meetingController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Enter meetup location"),
                    ),
                  ],
                ),
              );
            }
            /// ---------- STEP 2 ----------
            else if (step == 1) {
              section = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Fuel & Checkpoints",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fuelController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Estimated fuel stops"),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: checkpointController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            "Add checkpoint location",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (checkpointController.text.isNotEmpty) {
                            setModalState(() {
                              checkpoints.add(checkpointController.text);
                              checkpointController.clear();
                            });
                          }
                        },
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xfffe6603),
                          child: Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: checkpoints.asMap().entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff0f1114),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Color(0xfffe6603),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }
            /// ---------- STEP 3 ----------
            else if (step == 2) {
              section = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ride Rules",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rules.map((rule) {
                      final selected = selectedRules.contains(rule);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selected
                                ? selectedRules.remove(rule)
                                : selectedRules.add(rule);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xfffe6603)
                                : const Color(0xff0f1114),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            rule,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Add custom rule (optional)"),
                  ),
                ],
              );
            }
            /// ---------- STEP 4 (PREVIEW) ----------
            else {
              section = SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Preview",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _preview("Meeting Point", meetingController.text),
                    _preview("Fuel Stops", fuelController.text),
                    _preview("Rules", selectedRules.join(", ")),
                    const SizedBox(height: 10),
                    const Text(
                      "Checkpoints",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      children: checkpoints
                          .map(
                            (c) => ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.place,
                                color: Color(0xfffe6603),
                                size: 18,
                              ),
                              title: Text(
                                c,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Notes (optional)"),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Circle Step Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      bool done = index <= step;
                      return Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: done
                                  ? const Color(0xfffe6603)
                                  : Colors.white12,
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (index < 3)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: index < step
                                      ? const Color(0xfffe6603)
                                      : Colors.white12,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 14),

                  section,

                  const SizedBox(height: 16),

                  /// Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (step > 0)
                        TextButton(
                          onPressed: () => setModalState(() => step--),
                          child: const Text("Back"),
                        )
                      else
                        const SizedBox(), // placeholder for alignment

                      ElevatedButton(
                        onPressed: () {
                          if (step < 3) {
                            setModalState(() => step++);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(step == 3 ? "Save" : "Next"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Common input decoration for all text fields
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
      filled: true,
      fillColor: const Color(0xff0f1114),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Preview row for the last section
  Widget _preview(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              content.isEmpty ? "-" : content,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepContainer({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _checkpointCard({
    required int index,
    required String text,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff1a1c20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xfffe6603)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$index. $text",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _previewCard(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff1a1c20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xfffe6603)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _previewTile(String label, String value) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: $value",
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xff1a1c20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _locationField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true, // 🔥 ready for map picker
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.location_on, color: Color(0xfffe6603)),
        filled: true,
        fillColor: const Color(0xff1a1c20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onTap: () {
        // 👉 future: open map picker
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
