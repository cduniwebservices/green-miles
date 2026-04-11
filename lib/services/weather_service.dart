import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/fitness_models.dart';

/// Service to fetch weather and IP data from WeatherAPI.com
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  static const String _baseUrl = 'https://api.weatherapi.com/v1';
  
  // Use environment variable for API key
  final String _apiKey = const String.fromEnvironment('WEATHER_API_KEY');

  /// Fetch current weather for the given coordinates
  Future<WeatherData?> getCurrentWeather(double lat, double lon) async {
    if (_apiKey.isEmpty) {
      debugPrint('⚠️ WeatherService: API Key is missing. Weather data will not be fetched.');
      return null;
    }

    try {
      final url = Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$lat,$lon&aqi=no');
      
      debugPrint('🌍 WeatherService: Fetching weather for $lat, $lon...');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        final location = data['location'];
        
        // Calculate UTC Offset reliably
        final int epochSeconds = location['localtime_epoch'] as int;
        final String localTimeStr = location['localtime'] as String; // "2026-04-11 13:56"
        
        String calculatedOffset = '+00:00';
        try {
          final parts = localTimeStr.split(' ');
          final dateParts = parts[0].split('-');
          final timeParts = parts[1].split(':');

          // Create a UTC DateTime using the local clock values
          final localDateTimeAsUtc = DateTime.utc(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          // Find the difference in minutes
          final int localEpochMinutes = localDateTimeAsUtc.millisecondsSinceEpoch ~/ 60000;
          final int utcEpochMinutes = epochSeconds ~/ 60;
          final int offsetMinutes = localEpochMinutes - utcEpochMinutes;
          
          final int hours = offsetMinutes ~/ 60;
          final int mins = offsetMinutes % 60;
          calculatedOffset = "${hours >= 0 ? '+' : '-'}${hours.abs().toString().padLeft(2, '0')}:${mins.abs().toString().padLeft(2, '0')}";
        } catch (e) {
          debugPrint('⚠️ WeatherService: Offset calculation error: $e');
        }

        final weatherLocation = WeatherLocation(
          name: location['name'] as String? ?? '',
          region: location['region'] as String? ?? '',
          country: location['country'] as String? ?? '',
          tzId: location['tz_id'] as String? ?? '',
          localtimeEpoch: epochSeconds,
          localtime: localTimeStr,
          utcOffset: calculatedOffset,
        );

        final weather = WeatherData(
          location: weatherLocation,
          lastUpdated: current['last_updated'] as String? ?? '',
          lastUpdatedEpoch: current['last_updated_epoch'] as int? ?? 0,
          tempC: (current['temp_c'] as num? ?? 0).toDouble(),
          isDay: current['is_day'] as int? ?? 0,
          conditionText: current['condition']['text'] as String? ?? '',
          conditionIcon: current['condition']['icon'] as String? ?? '',
          conditionCode: current['condition']['code'] as int? ?? 0,
          windKph: (current['wind_kph'] as num? ?? 0).toDouble(),
          windDegree: current['wind_degree'] as int? ?? 0,
          windDir: current['wind_dir'] as String? ?? '',
          pressureMb: (current['pressure_mb'] as num? ?? 0).toDouble(),
          precipMm: (current['precip_mm'] as num? ?? 0).toDouble(),
          humidity: current['humidity'] as int? ?? 0,
          cloud: current['cloud'] as int? ?? 0,
          feelsLikeC: (current['feelslike_c'] as num? ?? 0).toDouble(),
          windChillC: (current['windchill_c'] as num? ?? 0).toDouble(),
          heatIndexC: (current['heatindex_c'] as num? ?? 0).toDouble(),
          dewPointC: (current['dewpoint_c'] as num? ?? 0).toDouble(),
          visKm: (current['vis_km'] as num? ?? 0).toDouble(),
          uv: (current['uv'] as num? ?? 0).toDouble(),
          gustKph: (current['gust_kph'] as num? ?? 0).toDouble(),
        );

        debugPrint('✅ WeatherService: Successfully fetched weather: ${weather.tempC}°C, ${weather.conditionText}');
        return weather;
      } else {
        debugPrint('❌ WeatherService: Failed to fetch weather. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ WeatherService: Error fetching weather: $e');
      return null;
    }
  }

  /// Fetch IP lookup data for the current user
  Future<IpLookupData?> getIpLookup() async {
    if (_apiKey.isEmpty) {
      debugPrint('⚠️ WeatherService: API Key is missing. IP lookup will not be performed.');
      return null;
    }

    try {
      final url = Uri.parse('$_baseUrl/ip.json?key=$_apiKey');
      
      debugPrint('🌍 WeatherService: Performing IP lookup...');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final ipLookup = IpLookupData(
          ip: data['ip'] as String? ?? '',
          type: data['type'] as String? ?? '',
          continentCode: data['continent_code'] as String? ?? '',
          continentName: data['continent_name'] as String? ?? '',
          countryCode: data['country_code'] as String? ?? '',
          countryName: data['country_name'] as String? ?? '',
          isEu: data['is_eu'] as bool? ?? false,
          geonameId: data['geoname_id'] as int? ?? 0,
          city: data['city'] as String? ?? '',
          region: data['region'] as String? ?? '',
        );

        debugPrint('✅ WeatherService: IP lookup successful: ${ipLookup.ip} (${ipLookup.city})');
        return ipLookup;
      } else {
        debugPrint('❌ WeatherService: IP lookup failed. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ WeatherService: Error during IP lookup: $e');
      return null;
    }
  }
}
