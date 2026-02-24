import 'package:flutter/material.dart';

class RideInfoScreen extends StatelessWidget {
  final Map<String, dynamic> rideGroup;

  const RideInfoScreen({super.key, required this.rideGroup});

  @override
  Widget build(BuildContext context) {
    final bool isActive = rideGroup["status"] == "active";

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: const Text("Ride Info"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ========================
          // HERO SECTION
          // ========================
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
                  rideGroup["name"],
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
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ========================
          // UPCOMING RIDE METRICS
          // ========================
          if (isActive) ...[
            const Text("Ride Plan",
                style: TextStyle(
                    color: Color(0xfffe6603),
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            _metricTile("Distance (Planned)", "120 km"),
            _metricTile("Estimated Duration", "3h 40m"),
            _metricTile("Difficulty", "Moderate"),
            _metricTile("Start Location", "Shell Petrol Pump"),
            _metricTile("Terrain", "Highway + Hills"),
            _metricTile("Weather Forecast", "22°C Clear"),

            const SizedBox(height: 24),

            const Text("Participation",
                style: TextStyle(
                    color: Color(0xfffe6603),
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            _metricTile("Riders Joined", "12"),
            _metricTile("Spots Remaining", "3"),
            _metricTile("Captain", "Vishal 👑"),
            _metricTile("Fuel Stops Planned", "2"),
            _metricTile("Route Shared", "Yes"),
          ],

          // ========================
          // COMPLETED RIDE METRICS
          // ========================
          if (!isActive) ...[
            const Text("Ride Summary",
                style: TextStyle(
                    color: Color(0xfffe6603),
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            _metricTile("Distance Covered", "118 km"),
            _metricTile("Total Duration", "3h 55m"),
            _metricTile("Average Speed", "72 km/h"),
            _metricTile("Max Speed", "128 km/h"),
            _metricTile("Total Stops", "3"),

            const SizedBox(height: 24),

            const Text("Participation Stats",
                style: TextStyle(
                    color: Color(0xfffe6603),
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            _metricTile("Riders Completed", "10"),
            _metricTile("Drop-offs", "2"),
            _metricTile("Top Rider", "Rahul 🏆"),
            _metricTile("Ride Rating", "4.8 ⭐"),
            _metricTile("Photos Uploaded", "36"),
          ],
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