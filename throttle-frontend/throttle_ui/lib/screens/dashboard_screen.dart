import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, "/createRide");
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            RideCard(
              title: "Sunday Mountain Ride",
              date: "March 20, 2026",
              difficulty: "Hard",
            ),
            RideCard(
              title: "City Night Cruise",
              date: "March 25, 2026",
              difficulty: "Easy",
            ),
          ],
        ),
      ),
    );
  }
}

class RideCard extends StatelessWidget {
  final String title;
  final String date;
  final String difficulty;

  const RideCard({
    super.key,
    required this.title,
    required this.date,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(date),
            const SizedBox(height: 4),
            Text("Difficulty: $difficulty"),
          ],
        ),
      ),
    );
  }
}
