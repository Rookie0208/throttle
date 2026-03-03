import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/ride_service.dart';

class PlanRideScreen extends StatefulWidget {
  final String token;

  const PlanRideScreen({super.key, required this.token});

  @override
  State<PlanRideScreen> createState() => _PlanRideScreenState();
}

class _PlanRideScreenState extends State<PlanRideScreen> {
  // ================= COLORS =================
  final bgColor = const Color(0xff0f1115);
  final cardColor = const Color(0xff1a1c20);
  final primaryColor = const Color(0xfffe6603);

  // ================= STATE =================
  String rideType = "SOLO";
  String difficulty = "EASY";

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = TimeOfDay.now();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final startLocationController = TextEditingController();
  final endLocationController = TextEditingController();
  final maxRidersController = TextEditingController();
  final rulesController = TextEditingController();

  List<String> selectedFriends = [];
  bool isLoading = false;

  // ------------------- STATE VARIABLES -------------------
  DateTime selectedStartTime = DateTime.now().add(const Duration(hours: 1));
  double startLat = 0.0;
  double startLng = 0.0;
  double endLat = 0.0;
  double endLng = 0.0;

  // ================= MAPBOX CONFIG =================
  final String mapboxToken = "<YOUR_MAPBOX_ACCESS_TOKEN>"; // add your token here

  // ================= UI HELPERS =================
  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white70, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget cardWrapper({required Widget child, bool disabled = false}) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: child,
      ),
    );
  }

  Widget modernField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool disabled = false,
    Function(String)? onSubmitted,
  }) {
    return cardWrapper(
      disabled: disabled,
      child: TextField(
        controller: controller,
        enabled: !disabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }

  // ================= DATE & TIME =================
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: selectedTime);

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  // ================= INVITE MODAL =================
  void openInviteFriendsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) {
        List<String> clubMembers = ["Rahul", "Amit", "Sneha", "Karan", "Vikram"];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Invite Club Members",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: clubMembers.length,
                        itemBuilder: (_, index) {
                          final member = clubMembers[index];
                          final isSelected = selectedFriends.contains(member);

                          return ListTile(
                            title:
                                Text(member, style: const TextStyle(color: Colors.white)),
                            trailing: Checkbox(
                              value: isSelected,
                              activeColor: primaryColor,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedFriends.add(member);
                                  } else {
                                    selectedFriends.remove(member);
                                  }
                                });
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Done"),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= GEOCODING =================
  Future<void> fetchCoordinates(String placeName, bool isStart) async {
    if (placeName.trim().isEmpty) return;

    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(placeName)}.json?access_token=$mapboxToken';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final coords = data['features'][0]['center'];
          final lng = coords[0];
          final lat = coords[1];

          setState(() {
            if (isStart) {
              startLat = lat;
              startLng = lng;
            } else {
              endLat = lat;
              endLng = lng;
            }
          });
        }
      }
    } catch (e) {
      showError("Failed to fetch coordinates");
    }
  }

  // ------------------- HELPER METHODS -------------------
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // ================= CREATE RIDE =================
  Future<void> createRide() async {
    if (titleController.text.trim().isEmpty) {
      showError("Title is required");
      return;
    }
    if (descriptionController.text.trim().isEmpty) {
      showError("Description is required");
      return;
    }
    if (startLocationController.text.trim().isEmpty ||
        endLocationController.text.trim().isEmpty) {
      showError("Start and End locations are required");
      return;
    }
    if (rideType == "GROUP" &&
        (maxRidersController.text.isEmpty ||
            int.tryParse(maxRidersController.text) == null)) {
      showError("Max Riders is required for group rides");
      return;
    }

    setState(() => isLoading = true);

    final rideData = {
      "title": titleController.text.trim(),
      "description": descriptionController.text.replaceAll("\n", " "),
      "rideType": rideType,
      "routeType": "HIGHWAY",
      "difficulty": difficulty,
      "startTime": selectedStartTime.toUtc().toIso8601String(),
      "visibility": "PUBLIC",
      "maxRiders":
          rideType == "GROUP" ? int.parse(maxRidersController.text) : 1,
      "rules": rulesController.text.isNotEmpty
          ? rulesController.text.split(",").map((e) => e.trim()).toList()
          : [],
      "invitedFriends": selectedFriends,
      "startLocation": {
        "name": startLocationController.text.trim(),
        "latitude": startLat,
        "longitude": startLng,
      },
      "endLocation": {
        "name": endLocationController.text.trim(),
        "latitude": endLat,
        "longitude": endLng,
      },
    };

    final result = await RideService.createRide(
      rideData,
      widget.token,
    );

    setState(() => isLoading = false);

    if (result["success"]) {
      showSuccess("Ride created successfully!");
      Navigator.pop(context);
    } else {
      showError(result["message"] ?? "Failed to create ride");
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text("Plan a Ride"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // RIDE TYPE
              sectionTitle("Ride Type"),
              Row(
                children: ["SOLO", "GROUP"].map((type) {
                  final selected = rideType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => rideType = type),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? primaryColor : cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(type,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // MAP PLACEHOLDER
              sectionTitle("Route Preview"),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(
                  child: Text("Map goes here",
                      style: TextStyle(color: Colors.white38)),
                ),
              ),
              const SizedBox(height: 20),

              // START LOCATION
              sectionTitle("Start Location"),
              modernField(
                controller: startLocationController,
                hint: "Enter start location",
                onSubmitted: (val) => fetchCoordinates(val, true),
              ),
              const SizedBox(height: 16),

              // END LOCATION
              sectionTitle("End Location"),
              modernField(
                controller: endLocationController,
                hint: "Enter end location",
                onSubmitted: (val) => fetchCoordinates(val, false),
              ),
              const SizedBox(height: 16),

              // TITLE
              sectionTitle("Title"),
              modernField(
                  controller: titleController, hint: "Sunday Morning Ride"),
              const SizedBox(height: 16),

              // DESCRIPTION
              sectionTitle("Description"),
              modernField(
                  controller: descriptionController,
                  hint: "Describe the ride...",
                  maxLines: 3),
              const SizedBox(height: 16),

              // RULES
              sectionTitle("Rules (comma separated)"),
              modernField(
                  controller: rulesController,
                  hint: "Helmet required, No rash riding"),
              const SizedBox(height: 16),

              // DATE & TIME
              sectionTitle("Date & Time"),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: pickDate,
                      child: cardWrapper(
                        child: Text(
                          "${selectedDate.toLocal()}".split(" ")[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: pickTime,
                      child: cardWrapper(
                        child: Text(
                          selectedTime.format(context),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // DIFFICULTY
              sectionTitle("Difficulty"),
              Row(
                children: ["EASY", "MODERATE", "HARD"].map((level) {
                  final selected = difficulty == level;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => difficulty = level),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? primaryColor : cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(level,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // MAX RIDERS
              sectionTitle("Max Riders"),
              modernField(
                controller: maxRidersController,
                hint: "Enter max riders",
                keyboardType: TextInputType.number,
                disabled: rideType == "SOLO",
              ),
              const SizedBox(height: 16),

              // INVITE FRIENDS
              sectionTitle("Invite Friends"),
              GestureDetector(
                onTap: rideType == "GROUP" ? openInviteFriendsModal : null,
                child: cardWrapper(
                  disabled: rideType == "SOLO",
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedFriends.isEmpty
                            ? "Select club members"
                            : "${selectedFriends.length} selected",
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.white54, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // CREATE BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : createRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Create Ride",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}