import '../models/ride_model.dart';

class LocalRideCache {
  static List<RideModel> myRides = [];

  static void addRide(RideModel ride) {
    myRides.insert(0, ride);
  }

  static List<RideModel> getRides() {
    return myRides;
  }
}