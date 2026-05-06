import 'package:geolocator/geolocator.dart';

enum LocationAccessState { granted, denied, deniedForever, serviceDisabled }

class AppPermissionService {
  static Future<LocationAccessState> getLocationAccessState() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationAccessState.serviceDisabled;
    }

    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  static Future<LocationAccessState> requestLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationAccessState.serviceDisabled;
    }

    final permission = await Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  static Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  static Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  static LocationAccessState _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccessState.granted;
      case LocationPermission.deniedForever:
        return LocationAccessState.deniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationAccessState.denied;
    }
  }
}
