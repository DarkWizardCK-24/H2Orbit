import 'package:flutter/material.dart';
import 'package:h2orbit/services/weather_service.dart';
import 'package:h2orbit/utils/helpers.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/glass_container.dart';

/// Current weather and how much it adds to today's goal.
class WeatherCard extends StatelessWidget {
  final WeatherSnapshot weather;

  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final description = weather.description.isEmpty
        ? ''
        : weather.description[0].toUpperCase() +
              weather.description.substring(1);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.warning.withValues(alpha: 0.2),
            ),
            child: Icon(weather.icon, color: AppTheme.warning, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weather.temperatureC.round()}°C  ·  $description',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${weather.city.isEmpty ? 'Your area' : weather.city}  ·  '
                  'Humidity ${weather.humidity}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (weather.bonusMl > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '+${Fmt.ml(weather.bonusMl)}',
                style: const TextStyle(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
