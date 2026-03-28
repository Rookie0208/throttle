import 'package:uuid/uuid.dart';

class RideLocalManager {
  static final RideLocalManager _instance = RideLocalManager._internal();
  factory RideLocalManager() => _instance;
  RideLocalManager._internal();

  final List<Map<String, dynamic>> _rides = [];
  final Map<String, List<Map<String, dynamic>>> _userRides = {};

  String currentUserId = "user_1"; // simulate logged in user

  List<Map<String, dynamic>> getUserRides(String userId) {
    return _userRides[userId] ?? [];
  }

  void createRide(Map<String, dynamic> rideData) {
    final rideId = const Uuid().v4();

    final ride = {
      "id": rideId,
      ...rideData,
      "creatorId": currentUserId,
      "members": [currentUserId, ...rideData["invitedUserIds"]],
    };

    _rides.add(ride);

    // Add ride to creator profile
    _userRides.putIfAbsent(currentUserId, () => []);
    _userRides[currentUserId]!.add(ride);

    // Add ride to invited users (simulate joined)
    for (var userId in rideData["invitedUserIds"]) {
      _userRides.putIfAbsent(userId, () => []);
      _userRides[userId]!.add(ride);
    }
  }
}
