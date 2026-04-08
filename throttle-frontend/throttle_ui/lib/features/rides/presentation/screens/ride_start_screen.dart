import 'package:flutter/material.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

class RideStartScreen extends StatefulWidget {
  final String groupName;
  final String rideDate;
  final String rideTime;
  final String location;
  final int memberCount;
  final String token;
  final String rideUuid;

  const RideStartScreen({
    super.key,
    required this.groupName,
    required this.rideDate,
    required this.rideTime,
    required this.location,
    required this.memberCount,
    required this.token,
    required this.rideUuid,
  });

  @override
  State<RideStartScreen> createState() => _RideStartScreenState();
}

class _RideStartScreenState extends State<RideStartScreen> {
  bool _isStarted = false;
  bool _expanded = false;

  int enRoute = 1;
  int atStart = 0;
  int inRide = 0;

  double _dragPosition = 0;

  String get title =>
      widget.groupName[0].toUpperCase() + widget.groupName.substring(1);

  void _endRide() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("End Ride", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to end this ride?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("End Ride"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          IconButton(
            onPressed: _endRide,
            icon: const Icon(Icons.stop_circle, color: Colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _rideCard(),
            const SizedBox(height: 20),
            _liveProgress(),
            const SizedBox(height: 20),
            _slider(),
            const SizedBox(height: 20),
            _accordion(),
          ],
        ),
      ),
    );
  }

  // 🔷 HEADER CARD
  Widget _rideCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.2), Colors.black],
        ),
        border: Border.all(color: Colors.blue.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "SCHEDULED",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _info(Icons.calendar_today, "Date", widget.rideDate),
              _info(Icons.access_time, "Time", widget.rideTime),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _info(Icons.location_on, "Meetup", widget.location),
              _info(Icons.people, "Riders", "${widget.memberCount} joined"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔷 LIVE PROGRESS (COMPACT)
  Widget _liveProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Text(
                "Live Progress",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              CircleAvatar(radius: 4, backgroundColor: Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _progressTile(
                Icons.navigation,
                "En Route",
                enRoute,
                Colors.orange,
              ),
              _progressTile(
                Icons.location_on,
                "At Start",
                atStart,
                Colors.green,
              ),
              _progressTile(Icons.navigation, "In Ride", inRide, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressTile(IconData icon, String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              "$count",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // 🔷 WORKING SLIDER
  Widget _slider() {
    final double maxWidth = MediaQuery.of(context).size.width - 32;
    const double thumbSize = 60;
    final double progress = _dragPosition / (maxWidth - thumbSize);

    return Container(
      width: maxWidth,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.7),
            Colors.yellow.withOpacity(0.7),
            Colors.green.withOpacity(0.7),
          ],
          stops: [0.0, progress.clamp(0.0, 1.0), 1.0],
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              _isStarted ? "MARK ARRIVED" : "START RIDE",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            left: _dragPosition,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragPosition += details.delta.dx;
                  _dragPosition = _dragPosition.clamp(
                    0,
                    maxWidth - thumbSize - 10,
                  );
                });
              },
              onHorizontalDragEnd: (_) {
                if (_dragPosition >= maxWidth - thumbSize - 10) {
                  setState(() {
                    _dragPosition = maxWidth - thumbSize - 10;
                    _isStarted = true;

                    // UX update
                    enRoute = 0;
                    atStart = widget.memberCount;
                  });
                  // Reset after a short delay
                  Future.delayed(const Duration(milliseconds: 500), () {
                    setState(() => _dragPosition = 0);
                  });
                  // TODO: call API
                } else {
                  setState(() => _dragPosition = 0);
                }
              },
              child: Container(
                width: thumbSize,
                height: thumbSize,
                margin: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔷 ACCORDION
  Widget _accordion() {
    return Column(
      children: [
        ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: () => setState(() => _expanded = !_expanded),
          leading: const Icon(Icons.info, color: Colors.blue),
          title: const Text(
            "How this works",
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            _expanded ? "Tap to hide" : "Tap to learn more",
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.white,
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: const [
                _HelpItem(
                  number: 1,
                  title: "Start Ride",
                  desc:
                      "Slide \"Start Ride\" when you're leaving home. This lets other riders know you're on your way.",
                ),
                SizedBox(height: 16),
                _HelpItem(
                  number: 2,
                  title: "Mark Arrived",
                  desc:
                      "Once you reach the meetup point, slide \"Mark Arrived\" so everyone knows you're ready.",
                ),
                SizedBox(height: 16),
                _HelpItem(
                  number: 3,
                  title: "Begin Journey",
                  desc:
                      "When the group is ready, the ride captain will start the full ride for everyone.",
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  final int number;
  final String title;
  final String desc;

  const _HelpItem({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number',
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
