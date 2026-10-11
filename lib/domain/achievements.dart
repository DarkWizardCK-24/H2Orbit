import 'package:flutter/material.dart';
import 'package:h2orbit/models/analytics_model.dart';
import 'package:h2orbit/utils/constants.dart';

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// The badges shown on the analytics screen. Unlocks are derived from the
/// user's data, so they stay correct after reinstalling or switching phones.
class AchievementCatalog {
  AchievementCatalog._();

  static const List<AchievementDef> all = [
    AchievementDef(
      id: 'first_sip',
      title: 'First Sip',
      description: 'Log your first drink',
      icon: Icons.water_drop_rounded,
    ),
    AchievementDef(
      id: 'streak_3',
      title: '3-Day Streak',
      description: 'Reach your goal 3 days in a row',
      icon: Icons.local_fire_department_rounded,
    ),
    AchievementDef(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Reach your goal 7 days in a row',
      icon: Icons.whatshot_rounded,
    ),
    AchievementDef(
      id: 'streak_30',
      title: 'Month Master',
      description: 'Reach your goal 30 days in a row',
      icon: Icons.emoji_events_rounded,
    ),
    AchievementDef(
      id: 'glasses_100',
      title: 'Century Club',
      description: 'Drink 100 glasses in total',
      icon: Icons.local_drink_rounded,
    ),
    AchievementDef(
      id: 'glasses_500',
      title: 'Ocean Explorer',
      description: 'Drink 500 glasses in total',
      icon: Icons.waves_rounded,
    ),
    AchievementDef(
      id: 'overachiever',
      title: 'Overachiever',
      description: 'Drink 150% of your goal in a day',
      icon: Icons.rocket_launch_rounded,
    ),
    AchievementDef(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Log a drink before 8 am',
      icon: Icons.wb_sunny_rounded,
    ),
  ];

  /// Ids of the achievements earned so far.
  static Set<String> unlocked(
    AnalyticsSummary summary, {
    required int allTimeMl,
  }) {
    final glasses = allTimeMl / AppConstants.mlPerGlass;
    return {
      if (allTimeMl > 0) 'first_sip',
      if (summary.longestStreak >= 3) 'streak_3',
      if (summary.longestStreak >= 7) 'streak_7',
      if (summary.longestStreak >= 30) 'streak_30',
      if (glasses >= 100) 'glasses_100',
      if (glasses >= 500) 'glasses_500',
      if (summary.bestDayRatio >= 1.5) 'overachiever',
      if (summary.earlyBirdDays > 0) 'early_bird',
    };
  }
}
