import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:h2orbit/domain/hydration_math.dart';
import 'package:h2orbit/services/location_service.dart';
import 'package:h2orbit/utils/constants.dart';
import 'package:http/http.dart' as http;

class WeatherSnapshot {
  final double temperatureC;
  final double feelsLikeC;
  final int humidity;
  final String description;
  final String iconCode;
  final String city;

  const WeatherSnapshot({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.description,
    required this.iconCode,
    required this.city,
  });

  /// Extra water suggested because of the heat.
  int get bonusMl => HydrationMath.weatherBonusMl(temperatureC);

  bool get isHot => temperatureC > 25;

  IconData get icon {
    switch (iconCode.length >= 2 ? iconCode.substring(0, 2) : '') {
      case '01':
        return iconCode.endsWith('n')
            ? Icons.nightlight_round
            : Icons.wb_sunny_rounded;
      case '02':
      case '03':
      case '04':
        return Icons.wb_cloudy_rounded;
      case '09':
      case '10':
        return Icons.grain_rounded;
      case '11':
        return Icons.thunderstorm_rounded;
      case '13':
        return Icons.ac_unit_rounded;
      default:
        return Icons.cloud_queue_rounded;
    }
  }

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    return WeatherSnapshot(
      temperatureC: (main['temp'] as num).toDouble(),
      feelsLikeC: (main['feels_like'] as num).toDouble(),
      humidity: (main['humidity'] as num).toInt(),
      description: weather['description'] as String? ?? '',
      iconCode: weather['icon'] as String? ?? '',
      city: json['name'] as String? ?? '',
    );
  }
}

/// Where the home screen gets the weather from (a fake in tests).
abstract class WeatherProvider {
  /// `false` when no API key was supplied; callers should skip weather then.
  bool get isConfigured;

  Future<WeatherSnapshot?> fetch();
}

class OpenWeatherProvider implements WeatherProvider {
  OpenWeatherProvider({
    String apiKey = AppConstants.openWeatherApiKey,
    http.Client? client,
    Future<Coordinates?> Function()? locate,
  }) : _apiKey = apiKey,
       _client = client ?? http.Client(),
       _locate = locate ?? LocationService.currentCoordinates;

  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  final String _apiKey;
  final http.Client _client;
  final Future<Coordinates?> Function() _locate;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Future<WeatherSnapshot?> fetch() async {
    if (!isConfigured) return null;
    try {
      final here = await _locate();
      if (here == null) return null;

      final url = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'lat': '${here.latitude}',
          'lon': '${here.longitude}',
          'units': 'metric',
          'appid': _apiKey,
        },
      );
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        debugPrint('Weather request failed: ${response.statusCode}');
        return null;
      }
      return WeatherSnapshot.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Could not load weather: $e');
      return null;
    }
  }
}
