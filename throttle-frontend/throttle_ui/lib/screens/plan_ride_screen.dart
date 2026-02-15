import 'package:flutter/material.dart';

class PlanRideScreen extends StatefulWidget {
  final VoidCallback onClose;

  const PlanRideScreen({super.key, required this.onClose});

  @override
  State<PlanRideScreen> createState() => _PlanRideScreenState();
}

class _PlanRideScreenState extends State<PlanRideScreen> {
  String rideType = "solo";
  String difficulty = "moderate";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plan a Ride"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ---------------- RIDE TYPE ----------------
            const Text(
              "Ride Type",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Row(
              children: ["solo", "group"].map((type) {
                bool selected = rideType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      icon: Icon(
                        type == "group"
                            ? Icons.group
                            : Icons.alt_route,
                        size: 18,
                      ),
                      label: Text(type.toUpperCase()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected
                            ? Colors.blue
                            : Colors.grey.shade200,
                        foregroundColor:
                            selected ? Colors.white : Colors.black,
                      ),
                      onPressed: () =>
                          setState(() => rideType = type),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            /// ---------------- MAP PLACEHOLDER ----------------
            const Text("Route Map",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text("Tap to select route on map"),
              ),
            ),

            const SizedBox(height: 20),

            /// ---------------- START LOCATION ----------------
            _locationCard("Start Location", "Santa Monica, CA",
                Colors.green),

            const SizedBox(height: 12),

            /// ---------------- END LOCATION ----------------
            _locationCard(
                "End Location", "Malibu, CA", Colors.red),

            const SizedBox(height: 12),

            /// ---------------- WAYPOINT ----------------
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text("Add waypoint"),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),

            const SizedBox(height: 20),

            /// ---------------- DATE & TIME ----------------
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                      Icons.calendar_today,
                      "Date",
                      "Feb 15, 2026"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                      Icons.access_time,
                      "Time",
                      "2:00 PM"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ---------------- DIFFICULTY ----------------
            const Text("Difficulty Level",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Row(
              children: ["easy", "moderate", "hard"]
                  .map((level) {
                bool selected = difficulty == level;
                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected
                            ? Colors.blue
                            : Colors.grey.shade200,
                        foregroundColor: selected
                            ? Colors.white
                            : Colors.black,
                      ),
                      onPressed: () =>
                          setState(() => difficulty = level),
                      child: Text(level.toUpperCase()),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            /// ---------------- ESTIMATES ----------------
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                      Icons.alt_route,
                      "Est. Distance",
                      "68 mi"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                      Icons.terrain,
                      "Est. Time",
                      "2h 15m"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ---------------- INVITE (ONLY GROUP) ----------------
            if (rideType == "group")
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text("Invite Riders",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.group),
                    label:
                        const Text("Select riders to invite"),
                    style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 50)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            /// ---------------- NOTES ----------------
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Add notes about the ride...",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// ---------------- CREATE BUTTON ----------------
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, 55)),
              child: const Text("Create Ride"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard(
      String label, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.location_pin, color: iconColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoCard(
      IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
