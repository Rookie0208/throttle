import 'package:flutter/material.dart';

class RideStatsScreen extends StatelessWidget {
  final String groupName;
  final String distance;
  final String duration;

  const RideStatsScreen({
    super.key,
    required this.groupName,
    required this.distance,
    required this.duration,
  });

  Widget statTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1a1c20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Color(0xfffe6603),
                  fontSize: 20,
                  fontWeight: FontWeight.bold))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: const Text("Ride Stats"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(groupName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 30),

            statTile("Distance", distance),
            const SizedBox(height: 10),
            statTile("Duration", duration),
          ],
        ),
      ),
    );
  }
}