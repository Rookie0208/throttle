class RideModel {
  final String id;
  final String title;
  final String description;
  final String rideType;
  final String difficulty;
  final DateTime startTime;
  final String creatorName;
  final List<String> members;
  final List<String> invited;

  RideModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rideType,
    required this.difficulty,
    required this.startTime,
    required this.creatorName,
    required this.members,
    required this.invited,
  });
}