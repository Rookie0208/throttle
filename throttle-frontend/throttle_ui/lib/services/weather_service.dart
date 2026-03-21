import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  /// Fetches current weather from Open-Meteo API
  static Future<Map<String, dynamic>?> getCurrentWeather(
      double lat, double lon) async {
    final String url =
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['current_weather'] != null) {
          final currentWeather = data['current_weather'];
          
          final temp = currentWeather['temperature'];
          final weatherCode = currentWeather['weathercode'];

          final weatherInfo = _getWeatherDescription(weatherCode);

          return {
            'temperature': temp.round().toString(),
            'description': weatherInfo['description'],
            'icon': weatherInfo['icon'],
            'isDay': currentWeather['is_day'] == 1,
          };
        }
      } else {
        print("Failed to load weather: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching weather: $e");
    }
    return null;
  }

  /// Maps WMO Weather interpretation codes to readable text and icons
  /// https://open-meteo.com/en/docs
  static Map<String, String> _getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return {'description': 'Clear sky', 'icon': 'cloud_off'}; // Icons.wb_sunny later
      case 1:
      case 2:
      case 3:
        return {'description': 'Partly Cloudy', 'icon': 'cloud'};
      case 45:
      case 48:
        return {'description': 'Fog', 'icon': 'foggy'}; // Icons.foggy
      case 51:
      case 53:
      case 55:
        return {'description': 'Drizzle', 'icon': 'grain'}; // Icons.grain
      case 56:
      case 57:
        return {'description': 'Freezing Drizzle', 'icon': 'ac_unit'};
      case 61:
      case 63:
      case 65:
        return {'description': 'Rain', 'icon': 'water_drop'}; // Icons.water_drop
      case 66:
      case 67:
        return {'description': 'Freezing Rain', 'icon': 'ac_unit'};
      case 71:
      case 73:
      case 75:
      case 77:
        return {'description': 'Snow', 'icon': 'ac_unit'}; // Icons.ac_unit
      case 80:
      case 81:
      case 82:
        return {'description': 'Rain Showers', 'icon': 'tsunami'}; 
      case 85:
      case 86:
        return {'description': 'Snow Showers', 'icon': 'ac_unit'};
      case 95:
      case 96:
      case 99:
        return {'description': 'Thunderstorm', 'icon': 'thunderstorm'}; // Icons.thunderstorm
      default:
        return {'description': 'Unknown', 'icon': 'cloud'};
    }
  }
}
