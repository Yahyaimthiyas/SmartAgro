import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherData {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final bool isDay;

  WeatherData({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current_weather'];
    return WeatherData(
      temperature: current['temperature'],
      windSpeed: current['windspeed'],
      weatherCode: current['weathercode'],
      isDay: current['is_day'] == 1,
    );
  }
}

class WeatherService {
  // OpenMeteo is free and requires no API key
  static const String _baseUrl = "https://api.open-meteo.com/v1/forecast";

  Future<WeatherData?> getCurrentWeather() async {
    try {
      // Get location
      final position = await _determinePosition();
      
      final url = Uri.parse(
          "$_baseUrl?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true");
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherData.fromJson(data);
      }
      return null;
    } catch (e) {
      print("Weather Error: $e");
      return null;
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
