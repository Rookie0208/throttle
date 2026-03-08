import 'package:flutter/material.dart';
import 'package:throttle_ui/services/group_service.dart';

class RideInfoScreen extends StatelessWidget {
  final Map<String, dynamic> rideGroup;
  final String token; // <-- you need to pass token from previous screen

  const RideInfoScreen({super.key, required this.rideGroup, required this.token});

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
                fontWeight: FontWeight.bold),
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
                fontWeight: FontWeight.bold),
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
                  return _metricTile(
                    m["name"] ?? "",
                    m["role"] ?? "",
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
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