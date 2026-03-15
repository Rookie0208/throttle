import 'package:flutter/material.dart';
import 'live_ride_screen.dart';

class RideStartScreen extends StatefulWidget {
  final String groupName;
  final String rideDate;
  final String rideTime;
  final String location;
  final int memberCount;

  const RideStartScreen({
    super.key,
    required this.groupName,
    required this.rideDate,
    required this.rideTime,
    required this.location,
    required this.memberCount,
  });

  @override
  State<RideStartScreen> createState() => _RideStartScreenState();
}

class _RideStartScreenState extends State<RideStartScreen> {

  double dragPosition = 0;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragPosition += details.delta.dx;

      if (dragPosition < 0) dragPosition = 0;
      if (dragPosition > 260) dragPosition = 260;
    });
  }

  void _handleDragEnd() {
    if (dragPosition > 250) {
      _startRide();
    } else {
      setState(() {
        dragPosition = 0;
      });
    }
  }

  void _startRide() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveRideScreen(
          groupName: widget.groupName,
          onEndRide: () {},
        ),
      ),
    );
  }

  Widget infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(color: Colors.white54),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),

      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: const Text("Start Ride"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// RIDE INFO CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff1a1c20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    widget.groupName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  infoTile(Icons.calendar_today,
                      "Date", widget.rideDate),

                  const SizedBox(height: 6),

                  infoTile(Icons.schedule,
                      "Time", widget.rideTime),

                  const SizedBox(height: 6),

                  infoTile(Icons.location_on,
                      "Start", widget.location),

                  const SizedBox(height: 6),

                  infoTile(Icons.people,
                      "Riders", "${widget.memberCount}"),

                ],
              ),
            ),

            const Spacer(),

            const Text(
              "Slide to Start Ride",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16),
            ),

            const SizedBox(height: 20),

            /// SLIDE BAR
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xff1a1c20),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Stack(
                children: [

                  Center(
                    child: Text(
                      "START RIDE",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  Positioned(
                    left: dragPosition,
                    top: 6,
                    child: GestureDetector(
                      onHorizontalDragUpdate: _handleDragUpdate,
                      onHorizontalDragEnd: (_) => _handleDragEnd(),
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xfffe6603),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.motorcycle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 40)
          ],
        ),
      ),
    );
  }
}