import 'package:flutter/material.dart';
import 'package:throttle_ui/features/rides/presentation/screens/plan_ride_screen.dart';
import 'package:throttle_ui/features/groups/data/services/group_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_refresh_notifier.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Public Rides")),
      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: applySearch,
              decoration: InputDecoration(
                hintText: "Search rides...",
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
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
                  dropdownColor: colorScheme.surface,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
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
                  icon: Icon(Icons.filter_list, color: colorScheme.primary),
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
                ? const Center(child: CircularProgressIndicator())
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
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 70,
            color: textTheme.bodySmall?.color?.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 20),

          Text(
            "No rides available",
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text("Be the first to create a ride 🚀", style: textTheme.bodyMedium),

          const SizedBox(height: 25),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlanRideScreen(token: widget.token),
                ),
              );
            },
            child: const Text("Create Ride"),
          ),
        ],
      ),
    );
  }

  /// ================= CARD =================
  Widget _rideCard(Map ride) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ride["title"] ?? "",
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          Text(ride["description"] ?? "", style: textTheme.bodyMedium),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(ride["rideType"] ?? "", style: textTheme.bodySmall),
              const SizedBox(width: 10),
              Text(ride["routeType"] ?? "", style: textTheme.bodySmall),
            ],
          ),

          const SizedBox(height: 10),

          ElevatedButton(
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
      RideRefreshNotifier.notify();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Joined ride successfully")));

      Navigator.pop(context); // go back to groups
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  /// ================= FILTER =================
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        final textTheme = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Filters", style: textTheme.titleMedium),

              ListTile(
                title: Text("Adventure", style: textTheme.bodyLarge),
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
                title: Text("City", style: textTheme.bodyLarge),
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
