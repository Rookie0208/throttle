import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'live_ride_screen.dart';

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
  bool _markedArrived = false;
  bool isCaptain = true; // TODO: fetch from API
  bool _fullRideStarted = false;
  bool _isDragging = false;

  int enRoute = 1;
  int atStart = 0;
  int inRide = 0;

  double _dragPosition = 0;

  String get title =>
      widget.groupName[0].toUpperCase() + widget.groupName.substring(1);

  void _endRide(AppThemeConfig theme) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text("End Ride", style: TextStyle(color: theme.textPrimary)),
        content: Text(
          "Are you sure you want to end this ride?",
          style: TextStyle(color: theme.textPrimary.withValues(alpha: 0.65)),
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
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.refresh, color: theme.textPrimary),
              ),
              IconButton(
                onPressed: () => _endRide(theme),
                icon: const Icon(Icons.stop_circle, color: Colors.red),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _rideCard(theme),
                const SizedBox(height: 20),
                _liveProgress(theme),
                const SizedBox(height: 20),
                if (!_markedArrived || isCaptain) _slider(theme),
                if (_markedArrived) ...[
                  const SizedBox(height: 20),
                  _arrivalMessage(theme),
                ],
                const SizedBox(height: 20),
                _accordion(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔷 HEADER CARD
  Widget _rideCard(AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.surface,
        border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 28,
                    letterSpacing: 1.2,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "SCHEDULED",
                  style: TextStyle(
                    color: Colors.amber,
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
              _info(Icons.calendar_today, "Date", widget.rideDate, theme),
              _info(Icons.access_time, "Time", widget.rideTime, theme),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _info(Icons.location_on, "Meetup", widget.location, theme),
              _info(
                Icons.people,
                "Riders",
                "${widget.memberCount} joined",
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(
    IconData icon,
    String label,
    String value,
    AppThemeConfig theme,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.65),
                  fontSize: 11,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔷 LIVE PROGRESS (COMPACT)
  Widget _liveProgress(AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "Live Progress",
                style: GoogleFonts.bebasNeue(
                  fontSize: 18,
                  letterSpacing: 1.1,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              CircleAvatar(radius: 4, backgroundColor: theme.primary),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _progressTile(
                Icons.navigation,
                "En Route",
                enRoute,
                theme.secondary,
                theme,
              ),
              _progressTile(
                Icons.location_on,
                "At Start",
                atStart,
                Colors.amber,
                theme,
              ),
              _progressTile(
                Icons.navigation,
                "In Ride",
                inRide,
                theme.primary,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressTile(
    IconData icon,
    String label,
    int count,
    Color color,
    AppThemeConfig theme,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              "$count",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.textPrimary.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔷 ARRIVAL MESSAGE
  Widget _arrivalMessage(AppThemeConfig theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You are at the meeting point",
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Waiting for others to join",
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.65),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔷 WORKING SLIDER
  Widget _slider(AppThemeConfig theme) {
    final double maxWidth = MediaQuery.of(context).size.width - 32;
    const double thumbSize = 60;
    final double maxDrag = maxWidth - thumbSize - 10;
    final double progress = (_dragPosition / maxDrag).clamp(0.0, 1.0);

    return Container(
      width: maxWidth,
      height: 70,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          // Active Track Fill
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _dragPosition + (thumbSize / 2) + 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primary.withValues(alpha: 0.05),
                    theme.primary.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          // Instruction Text
          Center(
            child: Opacity(
              opacity: (1.0 - progress * 1.8).clamp(0.0, 1.0),
              child: Text(
                _markedArrived
                    ? "START RIDE"
                    : (_isStarted ? "MARK ARRIVED" : "START RIDE"),
                style: GoogleFonts.bebasNeue(
                  fontSize: 22,
                  color: theme.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          // Animated Draggable Thumb
          AnimatedPositioned(
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: _dragPosition,
            child: GestureDetector(
              onHorizontalDragStart: (_) => setState(() => _isDragging = true),
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragPosition += details.delta.dx;
                  _dragPosition = _dragPosition.clamp(0, maxDrag);
                });
              },
              onHorizontalDragEnd: (_) {
                setState(() => _isDragging = false);

                if (_markedArrived && isCaptain && _dragPosition >= maxDrag) {
                  setState(() {
                    _dragPosition = maxDrag;
                    _fullRideStarted = true;

                    // Start the full ride
                    inRide = widget.memberCount;
                    atStart = 0;
                  });
                  // Reset after a short delay
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      setState(() => _dragPosition = 0);
                      // Navigate to live ride screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveRideScreen(
                            groupName: widget.groupName,
                            onEndRide: () => Navigator.pop(context),
                            token: widget.token,
                            rideUuid: widget.rideUuid,
                          ),
                        ),
                      );
                    }
                  });
                } else if (_isStarted &&
                    !_markedArrived &&
                    _dragPosition >= maxDrag) {
                  setState(() {
                    _dragPosition = maxDrag;
                    _markedArrived = true;

                    // Update progress
                    atStart =
                        widget.memberCount -
                        1; // assuming captain is already there
                  });
                  // Reset after a short delay
                  Future.delayed(const Duration(milliseconds: 500), () {
                    setState(() => _dragPosition = 0);
                  });
                } else if (_dragPosition >= maxDrag) {
                  setState(() {
                    _dragPosition = maxDrag;
                    _isStarted = true;

                    // UX update
                    enRoute = 0;
                    atStart = widget.memberCount;
                  });
                  // Reset after a short delay
                  Future.delayed(const Duration(milliseconds: 500), () {
                    setState(() => _dragPosition = 0);
                  });
                } else {
                  setState(() => _dragPosition = 0);
                }
              },
              child: AnimatedScale(
                scale: _isDragging ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔷 ACCORDION
  Widget _accordion(AppThemeConfig theme) {
    return Column(
      children: [
        ListTile(
          tileColor: theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: () => setState(() => _expanded = !_expanded),
          leading: Icon(Icons.info, color: theme.primary),
          title: Text(
            "How this works",
            style: GoogleFonts.bebasNeue(
              fontSize: 18,
              letterSpacing: 1.1,
              color: theme.textPrimary,
            ),
          ),
          subtitle: Text(
            _expanded ? "Tap to hide" : "Tap to learn more",
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.65),
              fontFamily: 'Inter',
            ),
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: theme.textPrimary,
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _HelpItem(
                  number: 1,
                  title: "Start Ride",
                  theme: theme,
                  desc:
                      "Slide \"Start Ride\" when you're leaving home. This lets other riders know you're on your way.",
                ),
                const SizedBox(height: 16),
                _HelpItem(
                  number: 2,
                  title: "Mark Arrived",
                  theme: theme,
                  desc:
                      "Once you reach the meetup point, slide \"Mark Arrived\" so everyone knows you're ready.",
                ),
                const SizedBox(height: 16),
                _HelpItem(
                  number: 3,
                  title: "Begin Journey",
                  theme: theme,
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
  final AppThemeConfig theme;

  const _HelpItem({
    required this.number,
    required this.title,
    required this.desc,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number',
          style: GoogleFonts.bebasNeue(color: theme.primary, fontSize: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.bebasNeue(
                  color: theme.textPrimary,
                  fontSize: 18,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.65),
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
