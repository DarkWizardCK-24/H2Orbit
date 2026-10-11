import 'package:flutter/foundation.dart';
import 'package:h2orbit/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Decides when to celebrate (and remembers what was already celebrated, per
/// user, so nothing fires twice).
class AchievementManager {
  AchievementManager({
    required this.userId,
    required NotificationGateway notifications,
  }) : _notifications = notifications;

  final String userId;
  final NotificationGateway _notifications;
  final Set<String> _celebrated = {};
  bool _loaded = false;

  /// True until something has been saved for this user. On that first run,
  /// milestones that were already earned are recorded quietly instead of
  /// sending a burst of old notifications.
  bool _firstRun = false;

  static const List<int> streakMilestones = [3, 7, 14, 30, 60, 100];
  static const List<int> glassMilestones = [50, 100, 250, 500, 1000];

  String get _storageKey => 'celebrated_achievements_$userId';

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey);
    _firstRun = saved == null;
    _celebrated.addAll(saved ?? const []);
    _loaded = true;
  }

  /// Returns `true` the first time [id] is claimed.
  Future<bool> _claim(String id) async {
    await _load();
    if (!_celebrated.add(id)) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _celebrated.toList());
    return true;
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Call whenever the day's total changes.
  Future<void> onProgress({
    required int intakeMl,
    required int goalMl,
    required int streak,
    required int allTimeGlasses,
    required DateTime now,
  }) async {
    try {
      final day = _dayKey(now);

      if (goalMl > 0 && intakeMl >= goalMl && await _claim('goal_$day')) {
        await _notifications.goalReached();
      }
      if (goalMl > 0 && intakeMl >= goalMl * 1.5 && await _claim('over_$day')) {
        await _notifications.achievement(
          title: 'Overachiever!',
          body: 'You drank 50% more than your daily goal.',
          payload: 'overachiever',
        );
      }

      for (final days in streakMilestones) {
        if (streak >= days && await _claim('streak_$days') && !_firstRun) {
          await _notifications.achievement(
            title: _streakTitle(days),
            body: '$days days in a row of reaching your goal. Keep going!',
            payload: 'streak_$days',
          );
        }
      }

      for (final glasses in glassMilestones) {
        if (allTimeGlasses >= glasses &&
            await _claim('glasses_$glasses') &&
            !_firstRun) {
          await _notifications.achievement(
            title: '$glasses glasses!',
            body: "You've logged $glasses glasses of water in total.",
            payload: 'glasses_$glasses',
          );
        }
      }
      _firstRun = false;
    } catch (e) {
      debugPrint('Achievement check failed: $e');
    }
  }

  /// Call right after a drink is logged.
  Future<void> onDrinkLogged(DateTime now) async {
    try {
      final day = _dayKey(now);
      if (now.hour < 8 && await _claim('early_$day')) {
        await _notifications.achievement(
          title: 'Early bird!',
          body: 'Starting the day with a drink - great habit.',
          payload: 'early_bird',
        );
      }
      if (now.hour >= 22 && await _claim('night_$day')) {
        await _notifications.achievement(
          title: 'Night owl',
          body: "Still hydrating late - just don't forget to rest too.",
          payload: 'night_owl',
        );
      }
    } catch (e) {
      debugPrint('Achievement check failed: $e');
    }
  }

  static String _streakTitle(int days) {
    switch (days) {
      case 3:
        return '3-day streak!';
      case 7:
        return 'Week warrior!';
      case 14:
        return 'Two-week champion!';
      case 30:
        return 'Monthly master!';
      case 60:
        return 'Diamond hydrator!';
      default:
        return '$days-day streak!';
    }
  }
}
