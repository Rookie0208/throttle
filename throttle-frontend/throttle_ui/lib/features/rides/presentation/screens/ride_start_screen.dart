import 'package:flutter/material.dart';
import 'live_ride_screen.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

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
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(color: AppColors.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    widget.groupName,
                    style: const TextStyle(
                      color: AppColors.white,
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
                  color: AppColors.textSecondary,
                  fontSize: 16),
            ),

            const SizedBox(height: 20),

            /// SLIDE BAR
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Stack(
                children: [

                  Center(
                    child: Text(
                      "START RIDE",
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.4),
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
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.motorcycle,
                          color: AppColors.white,
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