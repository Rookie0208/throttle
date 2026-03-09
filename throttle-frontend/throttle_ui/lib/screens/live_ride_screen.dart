import 'package:flutter/material.dart';

class LiveRideScreen extends StatelessWidget {
  final String groupName;
  final VoidCallback onEndRide;

  const LiveRideScreen({
    super.key,
    required this.groupName,
    required this.onEndRide,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: Text("$groupName - Live Ride"),
      ),
      body: Column(
        children: [

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff1a1c20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text("Current Speed",
                    style: TextStyle(color: Colors.white70)),
                SizedBox(height: 6),
                Text("45 mph",
                    style: TextStyle(
                        fontSize: 32,
                        color: Color(0xfffe6603),
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const Spacer(),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            onPressed: onEndRide,
            child: const Text("End Ride"),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}