import '../models/ride_model.dart';

class DemoRideService {
  static final List<RideModel> _rides = [];

  static List<Map<String, String>> demoFriends = [
    {"id": "1", "name": "John Rider"},
    {"id": "2", "name": "Sarah Blaze"},
    {"id": "3", "name": "Mike Torque"},
  ];

  static List<RideModel> getMyRides() {
    return _rides;
  }

  static void createRide({
    required String title,
    required String description,
    required String rideType,
    required String difficulty,
    required DateTime startTime,
    required List<String> invitedIds,
  }) {
    final ride = RideModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      rideType: rideType,
      difficulty: difficulty,
      startTime: startTime,
      creatorName: "Alex Rider",
      members: ["Alex Rider"],
      invited: invitedIds,
    );

    _rides.insert(0, ride);
  }

  static void joinRide(String rideId) {
    final ride = _rides.firstWhere((r) => r.id == rideId);
    if (!ride.members.contains("Alex Rider")) {
      ride.members.add("Alex Rider");
    }
  }
}
