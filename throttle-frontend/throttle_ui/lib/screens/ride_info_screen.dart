import 'package:flutter/material.dart';

class RideInfoScreen extends StatelessWidget {
  final Map<String, dynamic> ride;

  const RideInfoScreen({super.key, required this.ride});

  bool get isActive => ride["status"] == "active";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride Info"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isActive ? _activeRide() : _completedRide(),
      ),
    );
  }

  /// ACTIVE RIDE UI
  Widget _activeRide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _sectionTitle("Ride Details"),

        _grid([
          _tile("Ride Date", ride["rideDate"]),
          _tile("Meetup Time", ride["meetupTime"]),
          _tile("Distance", ride["distance"]),
          _tile("Duration", ride["duration"]),
          _tile("Difficulty", ride["difficulty"]),
          _tile("Terrain", ride["terrain"]),
          _tile("Weather", ride["weather"]),
        ]),

        const SizedBox(height: 20),

        _sectionTitle("Location"),

        _fullTile("Start Location", ride["startLocation"]),

        const SizedBox(height: 20),

        _sectionTitle("Participation"),

        _grid([
          _tile("Captain", ride["captain"]),
          _tile("Fuel Stops", ride["fuelStops"]),
          _tile("Route Shared", ride["routeShared"]),
          _tile("Participants", ride["participants"]),
        ]),

        const SizedBox(height: 25),

        _participants(),
      ],
    );
  }

  /// COMPLETED RIDE UI
  Widget _completedRide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _sectionTitle("Ride Summary"),

        _grid([
          _tile("Ride Date", ride["rideDate"]),
          _tile("Meetup Time", ride["meetupTime"]),
          _tile("Distance Covered", ride["distanceCovered"]),
          _tile("Total Duration", ride["totalDuration"]),
          _tile("Average Speed", ride["avgSpeed"]),
          _tile("Max Speed", ride["maxSpeed"]),
          _tile("Stops", ride["stops"]),
        ]),

        const SizedBox(height: 20),

        _sectionTitle("Ride Results"),

        _grid([
          _tile("Riders Completed", ride["ridersCompleted"]),
          _tile("Drop-offs", ride["dropOffs"]),
          _tile("Top Rider", ride["topRider"]),
          _tile("Ride Rating", ride["rideRating"]),
        ]),

        const SizedBox(height: 25),

        _sectionTitle("Photos"),

        _photos(),

        const SizedBox(height: 25),

        _participants(),
      ],
    );
  }

  /// SECTION TITLE
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// GRID WRAPPER
  Widget _grid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      children: children,
    );
  }

  /// SMALL INFO TILE
  Widget _tile(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              )),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? "-",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// FULL WIDTH TILE
  Widget _fullTile(String label, dynamic value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value?.toString() ?? "-"),
          )
        ],
      ),
    );
  }

  /// PARTICIPANTS LIST
  Widget _participants() {
    final members = ride["members"] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Participants"),
        ListView.builder(
          itemCount: members.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final m = members[index];

            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(m["name"]),
              subtitle: Text(m["role"] ?? "Rider"),
            );
          },
        )
      ],
    );
  }

  /// PHOTO GRID
  Widget _photos() {
    final photos = ride["photos"] ?? [];

    if (photos.isEmpty) {
      return const Text("No photos uploaded");
    }

    return GridView.builder(
      itemCount: photos.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            photos[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}