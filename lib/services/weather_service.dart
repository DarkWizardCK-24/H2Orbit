import 'dart:convert';
import 'package:h2orbit/services/location_service.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  // Use OpenWeatherMap free API - you'll need to get your own API key
  static const String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherData?> getCurrentWeather() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) return null;

      final url = Uri.parse(
        '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
    return null;
  }

  static String getHydrationRecommendation(
    double temperature,
    double humidity,
  ) {
    if (temperature > 35) {
      return 'Extreme heat! Increase water intake by 30-40%. Drink every 15-20 minutes.';
    } else if (temperature > 30) {
      return 'Very hot weather! Increase water intake by 20-30%.';
    } else if (temperature > 25) {
      return 'Warm day ahead! Add 10-20% more water to your goal.';
    } else if (temperature < 10) {
      return 'Cold weather! Don\'t forget to stay hydrated even when it\'s cold.';
    }

    if (humidity > 80) {
      return 'High humidity! You\'re sweating more than you think. Drink extra water.';
    } else if (humidity < 30) {
      return 'Dry air! Your body loses moisture faster. Stay hydrated.';
    }

    return 'Perfect weather for staying active! Maintain your hydration routine.';
  }

  static int calculateExtraWaterNeeded(double temperature) {
    if (temperature > 35) {
      return 1000; // Extra 1L
    } else if (temperature > 30) {
      return 750; // Extra 750ml
    } else if (temperature > 25) {
      return 500; // Extra 500ml
    }
    return 0;
  }
}

class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String description;
  final String iconCode;
  final String cityName;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.description,
    required this.iconCode,
    required this.cityName,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['main']['temp'].toDouble(),
      feelsLike: json['main']['feels_like'].toDouble(),
      humidity: json['main']['humidity'],
      description: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
      cityName: json['name'],
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
}
