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

  final Color primaryColor = const Color(0xfffe6603);
  final Color backgroundColor = const Color(0xff0f1115);
  final Color cardColor = const Color(0xff1a1c22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade800),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Plan a Ride",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// Ride Type
                    sectionTitle("Ride Type"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        rideTypeButton("solo", Icons.route),
                        const SizedBox(width: 10),
                        rideTypeButton("group", Icons.group),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// Route Map Placeholder
                    sectionTitle("Route Map"),
                    const SizedBox(height: 8),
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: const Center(
                        child: Text(
                          "Tap to select route on map",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Start Location
                    locationTile("Start Location", "Santa Monica, CA",
                        Icons.location_on, Colors.green),

                    const SizedBox(height: 10),

                    /// End Location
                    locationTile("End Location", "Malibu, CA",
                        Icons.location_on, Colors.red),

                    const SizedBox(height: 10),

                    /// Add Waypoint
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.grey.shade700,
                            style: BorderStyle.solid),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white54),
                          SizedBox(width: 10),
                          Text("Add waypoint",
                              style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: infoCard("Date", "Feb 15, 2026",
                              Icons.calendar_today),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child:
                              infoCard("Time", "2:00 PM", Icons.access_time),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// Difficulty
                    sectionTitle("Difficulty Level"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        difficultyButton("easy"),
                        const SizedBox(width: 8),
                        difficultyButton("moderate"),
                        const SizedBox(width: 8),
                        difficultyButton("hard"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// Estimates
                    Row(
                      children: [
                        Expanded(
                          child: estimateCard(
                              "Est. Distance", "68 mi", Icons.route),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: estimateCard(
                              "Est. Time", "2h 15m", Icons.terrain),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// Invite Riders (Only if group)
                    if (rideType == "group") ...[
                      sectionTitle("Invite Riders"),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.group, color: Colors.white54),
                            SizedBox(width: 10),
                            Text("Select riders to invite",
                                style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    /// Notes
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.note, color: Colors.white54),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text("Add notes about the ride...",
                                style: TextStyle(color: Colors.white54)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// Create Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "Create Ride",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- Widgets ----------------

  Widget sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget rideTypeButton(String type, IconData icon) {
    final bool selected = rideType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => rideType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? primaryColor.withOpacity(0.1) : cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? primaryColor : Colors.grey.shade800),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? primaryColor : Colors.white54),
              const SizedBox(width: 6),
              Text(
                type.toUpperCase(),
                style: TextStyle(
                  color: selected ? primaryColor : Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget difficultyButton(String value) {
    final bool selected = difficulty == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => difficulty = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? primaryColor.withOpacity(0.1) : cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? primaryColor : Colors.grey.shade800),
          ),
          child: Center(
            child: Text(
              value.toUpperCase(),
              style: TextStyle(
                color: selected ? primaryColor : Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget locationTile(
      String title, String location, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
              Text(location,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget infoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget estimateCard(String label, String value, IconData icon) {
    return infoCard(label, value, icon);
  }
}
