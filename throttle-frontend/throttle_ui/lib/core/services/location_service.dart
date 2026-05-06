import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'logger_service.dart';

class LocationService {
  static Future<LocationPermission?> ensureLocationPermission({
    bool requestPermission = true,
  }) async {
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!requestPermission) {
        return permission;
      }
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return permission;
  }

  /// Requests permission and gets the current location.
  static Future<Position?> getCurrentLocation({
    bool requestPermission = true,
  }) async {
    final permission = await ensureLocationPermission(
      requestPermission: requestPermission,
    );
    if (permission == null) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  }

  /// Gets the city name from a given latitude and longitude
  static Future<String?> getCityName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final city = place.locality ?? place.subAdministrativeArea;
        if (city != null && city.isNotEmpty) return city;
      }
    } catch (e) {
      Logger.warn(
        "Primary geocoder failed (likely missing API key), trying fallback...",
      );
      try {
        // Fallback to free OpenStreetMap API so you don't need a Google Maps API Key
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude',
        );
        final response = await http.get(
          url,
          headers: {'User-Agent': 'ThrottleAppHelper/1.0'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['address'] != null) {
            return data['address']['city'] ??
                data['address']['town'] ??
                data['address']['village'] ??
                data['address']['county'] ??
                "Unknown City";
          }
        }
      } catch (fallbackError) {
        Logger.error("Fallback geocoding also failed: $fallbackError");
      }
    }
    return null;
  }
}
