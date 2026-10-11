import 'package:flutter/material.dart';
import 'package:h2orbit/domain/hydration_math.dart';
import 'package:h2orbit/models/user_model.dart';
import 'package:h2orbit/services/weather_service.dart';
import 'package:h2orbit/utils/constants.dart';
import 'package:h2orbit/utils/helpers.dart';

enum TipKind { success, warning, info }

class CoachTip {
  final TipKind kind;
  final String title;
  final String message;
  final IconData icon;

  /// Lower numbers are shown first.
  final int priority;

  const CoachTip({
    required this.kind,
    required this.title,
    required this.message,
    required this.icon,
    required this.priority,
  });
}

/// Rule-based hydration coach. It looks at the time of day, how much has been
/// drunk, the weather and the user's profile and returns the most relevant
/// tips first. (It is deterministic: the same inputs always give the same tips.)
class HydrationCoach {
  HydrationCoach._();

  /// First and last hour of the day the user is expected to be drinking.
  static const int wakeHour = 7;
  static const int sleepHour = 22;

  /// How far through the day's goal you should be by [now] (0.0 - 1.0).
  static double expectedProgress(DateTime now) {
    final hours = now.hour + now.minute / 60;
    if (hours <= wakeHour) return 0;
    if (hours >= sleepHour) return 1;
    return (hours - wakeHour) / (sleepHour - wakeHour);
  }

  static List<CoachTip> tips({
    required int intakeMl,
    required int goalMl,
    required DateTime now,
    UserModel? user,
    WeatherSnapshot? weather,
    int caffeineMg = 0,
  }) {
    final tips = <CoachTip>[];
    final progress = goalMl > 0 ? intakeMl / goalMl : 0.0;
    final remainingMl = goalMl > intakeMl ? goalMl - intakeMl : 0;

    // 1. Where the user stands against the goal.
    if (progress >= 1.5) {
      tips.add(
        const CoachTip(
          kind: TipKind.success,
          title: 'Overachiever!',
          message:
              'You are well past your goal today. Listen to your body and '
              'sip only if you are thirsty.',
          icon: Icons.rocket_launch_rounded,
          priority: 0,
        ),
      );
    } else if (progress >= 1) {
      tips.add(
        const CoachTip(
          kind: TipKind.success,
          title: 'Goal reached',
          message: 'Great work! Keep sipping steadily to stay topped up.',
          icon: Icons.emoji_events_rounded,
          priority: 0,
        ),
      );
    } else {
      final expectedMl = (expectedProgress(now) * goalMl).round();
      final behindMl = expectedMl - intakeMl;
      if (behindMl >= AppConstants.mlPerGlass) {
        // behindMl <= remainingMl, so the upper bound is always >= 50.
        final catchUp = ((behindMl / 50).ceil() * 50)
            .clamp(50, remainingMl)
            .toInt();
        tips.add(
          CoachTip(
            kind: TipKind.warning,
            title: 'A little behind schedule',
            message:
                'Have about ${Fmt.ml(catchUp)} soon to get back on track '
                'for ${Fmt.ml(goalMl)} today.',
            icon: Icons.schedule_rounded,
            priority: 0,
          ),
        );
      } else if (remainingMl <= AppConstants.mlPerGlass * 2 && intakeMl > 0) {
        tips.add(
          CoachTip(
            kind: TipKind.success,
            title: 'Almost there',
            message:
                'Only ${Fmt.ml(remainingMl)} to go - '
                '${(remainingMl / AppConstants.mlPerGlass).ceil()} more '
                '${remainingMl <= AppConstants.mlPerGlass ? 'glass' : 'glasses'}.',
            icon: Icons.flag_rounded,
            priority: 0,
          ),
        );
      } else if (now.hour >= wakeHour) {
        tips.add(
          const CoachTip(
            kind: TipKind.success,
            title: 'Right on track',
            message: 'You are keeping pace with your goal. Keep it up!',
            icon: Icons.trending_up_rounded,
            priority: 1,
          ),
        );
      }
    }

    // 2. Weather.
    if (weather != null && weather.bonusMl > 0) {
      tips.add(
        CoachTip(
          kind: TipKind.info,
          title:
              'Hot day in ${weather.city.isEmpty ? 'your area' : weather.city}',
          message:
              'It is ${weather.temperatureC.round()}°C, so your goal includes '
              '${Fmt.ml(weather.bonusMl)} extra. Drink before you feel thirsty.',
          icon: Icons.wb_sunny_rounded,
          priority: 2,
        ),
      );
    }

    // 3. Caffeine.
    if (caffeineMg >= 200) {
      final extraGlasses = (caffeineMg * 0.5 / AppConstants.mlPerGlass).ceil();
      tips.add(
        CoachTip(
          kind: TipKind.info,
          title: 'Lots of caffeine today',
          message:
              'About $caffeineMg mg so far. Add $extraGlasses extra '
              '${extraGlasses == 1 ? 'glass' : 'glasses'} of water to balance it.',
          icon: Icons.coffee_rounded,
          priority: 3,
        ),
      );
    }

    // 4. Goal vs. what the profile suggests.
    if (user != null) {
      final recommended = HydrationMath.recommendedDailyMl(
        weightKg: user.weightKg,
        age: user.age,
        gender: user.gender,
      );
      if (user.dailyGoalMl < recommended * 0.8) {
        tips.add(
          CoachTip(
            kind: TipKind.info,
            title: 'Your goal looks low',
            message:
                'For your weight, about ${Fmt.ml(recommended)} '
                '(${Fmt.glasses(recommended)} glasses) is typical. '
                'You can change it in your profile.',
            icon: Icons.tune_rounded,
            priority: 4,
          ),
        );
      }
    }

    // 5. A habit for this time of day.
    tips.add(_habitFor(now, intakeMl));

    tips.sort((a, b) => a.priority.compareTo(b.priority));
    return tips;
  }

  static CoachTip _habitFor(DateTime now, int intakeMl) {
    final h = now.hour;
    if (h >= 5 && h < 10 && intakeMl == 0) {
      return const CoachTip(
        kind: TipKind.info,
        title: 'Start the day with water',
        message:
            'A glass before your tea or coffee rehydrates you after the night.',
        icon: Icons.wb_twilight_rounded,
        priority: 5,
      );
    }
    if (h >= 12 && h < 14) {
      return const CoachTip(
        kind: TipKind.info,
        title: 'Lunchtime habit',
        message:
            'A glass of water about 30 minutes before a meal helps digestion.',
        icon: Icons.restaurant_rounded,
        priority: 5,
      );
    }
    if (h >= 21 || h < 5) {
      return const CoachTip(
        kind: TipKind.info,
        title: 'Wind down gently',
        message:
            'Small sips are fine, but avoid drinking a lot right before bed.',
        icon: Icons.bedtime_rounded,
        priority: 5,
      );
    }

    const general = [
      'Keep a bottle where you can see it - you will drink more.',
      'Pair a glass of water with something you already do every hour.',
      'Thirst is a late signal. Sip regularly instead of waiting for it.',
      'Your future self will thank you for staying hydrated today.',
    ];
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return CoachTip(
      kind: TipKind.info,
      title: 'Hydration tip',
      message: general[dayOfYear % general.length],
      icon: Icons.lightbulb_rounded,
      priority: 5,
    );
  }
}
