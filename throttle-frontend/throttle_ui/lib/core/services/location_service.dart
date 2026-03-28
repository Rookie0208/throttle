import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'logger_service.dart';

class LocationService {
  /// Requests permission and gets the current location
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      return null;
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
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
      Logger.warn("Primary geocoder failed (likely missing API key), trying fallback...");
      try {
        // Fallback to free OpenStreetMap API so you don't need a Google Maps API Key
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude');
        final response = await http.get(url, headers: {
          'User-Agent': 'ThrottleAppHelper/1.0',
        });
        
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
