import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/plan_ride_screen.dart';
import 'package:throttle_ui/services/group_service.dart';
import 'package:throttle_ui/utils/app_colors.dart';

class PublicRidesScreen extends StatefulWidget {
  final String token;

  const PublicRidesScreen({super.key, required this.token});

  @override
  State<PublicRidesScreen> createState() => _PublicRidesScreenState();
}

class _PublicRidesScreenState extends State<PublicRidesScreen> {
  List rides = [];
  List filteredRides = [];

  bool loading = true;

  String searchQuery = "";
  String selectedSort = "latest";

  /// ================= FETCH =================
  Future<void> fetchPublicRides() async {
    try {
      final result = await GroupService.fetchPublicRides(widget.token);

      setState(() {
        rides = result["data"] ?? [];
        filteredRides = rides;
        loading = false;
      });
    } catch (e) {
      loading = false;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPublicRides();
  }

  /// ================= SEARCH =================
  void applySearch(String query) {
    setState(() {
      searchQuery = query;

      filteredRides = rides.where((r) {
        return (r["title"] ?? "").toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  /// ================= SORT =================
  void applySort(String type) {
    setState(() {
      selectedSort = type;

      if (type == "latest") {
        filteredRides.sort((a, b) => b["startTime"].compareTo(a["startTime"]));
      } else if (type == "riders") {
        filteredRides.sort(
          (a, b) => (b["maxRiders"] ?? 0).compareTo(a["maxRiders"] ?? 0),
        );
      }
    });
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Public Rides"),
      ),
      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: applySearch,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "Search rides...",
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// SORT + FILTER ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selectedSort,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: const [
                    DropdownMenuItem(value: "latest", child: Text("Latest")),
                    DropdownMenuItem(
                      value: "riders",
                      child: Text("Max Riders"),
                    ),
                  ],
                  onChanged: (v) => applySort(v!),
                ),

                const Spacer(),

                IconButton(
                  icon: const Icon(Icons.filter_list, color: AppColors.white),
                  onPressed: () {
                    _openFilterSheet();
                  },
                ),
              ],
            ),
          ),

          /// LIST
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredRides.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredRides.length,
                    itemBuilder: (context, index) {
                      final ride = filteredRides[index];
                      return _rideCard(ride);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 70, color: AppColors.white30),
          const SizedBox(height: 20),

          const Text(
            "No rides available",
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Be the first to create a ride 🚀",
            style: TextStyle(color: AppColors.textMuted),
          ),

          const SizedBox(height: 25),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => PlanRideScreen(token: widget.token)));
            },
            child: const Text("Create Ride", style: TextStyle(color: AppColors.white),),
          ),
        ],
      ),
    );
  }

  /// ================= CARD =================
  Widget _rideCard(Map ride) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ride["title"] ?? "",
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            ride["description"] ?? "",
            style: const TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                ride["rideType"] ?? "",
                style: const TextStyle(color: AppColors.textHint),
              ),
              const SizedBox(width: 10),
              Text(
                ride["routeType"] ?? "",
                style: const TextStyle(color: AppColors.textHint),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () {
              _joinRide(ride["uuid"]);
            },
            child: const Text("Join Ride"),
          ),
        ],
      ),
    );
  }

  /// ================= JOIN =================
  void _joinRide(String rideId) async {
    try {
      await GroupService.joinRide(widget.token, rideId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Joined ride successfully")));

      Navigator.pop(context); // go back to groups
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to join ride")));
    }
  }

  /// ================= FILTER =================
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Filters",
                style: TextStyle(color: AppColors.white, fontSize: 18),
              ),

              ListTile(
                title: const Text(
                  "Adventure",
                  style: TextStyle(color: AppColors.white),
                ),
                onTap: () {
                  setState(() {
                    filteredRides = rides
                        .where((r) => r["rideType"] == "ADVENTURE")
                        .toList();
                  });
                  Navigator.pop(context);
                },
              ),

              ListTile(
                title: const Text(
                  "City",
                  style: TextStyle(color: AppColors.white),
                ),
                onTap: () {
                  setState(() {
                    filteredRides = rides
                        .where((r) => r["routeType"] == "CITY")
                        .toList();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
