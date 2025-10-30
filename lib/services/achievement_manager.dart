import 'package:h2orbit/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementManager {
  static final AchievementManager _instance = AchievementManager._internal();
  factory AchievementManager() => _instance;
  AchievementManager._internal();

  final NotificationService _notificationService = NotificationService();
  final Set<String> _unlockedAchievements = {};

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final achievements = prefs.getStringList('unlocked_achievements') ?? [];
    _unlockedAchievements.addAll(achievements);
  }

  Future<void> _unlockAchievement(String achievementId) async {
    if (_unlockedAchievements.contains(achievementId)) return;

    _unlockedAchievements.add(achievementId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'unlocked_achievements',
      _unlockedAchievements.toList(),
    );
  }

  // Check and notify for streak achievements
  Future<void> checkStreakAchievement(int currentStreak) async {
    final milestones = [3, 7, 14, 30, 60, 100];

    for (final milestone in milestones) {
      if (currentStreak == milestone) {
        final achievementId = 'streak_$milestone';
        if (!_unlockedAchievements.contains(achievementId)) {
          await _unlockAchievement(achievementId);
          await _notificationService.showStreakAchievement(milestone);
        }
      }
    }
  }

  // Check and notify for total glasses milestone
  Future<void> checkGlassMilestone(int totalGlasses) async {
    final milestones = [50, 100, 250, 500, 1000];

    for (final milestone in milestones) {
      if (totalGlasses >= milestone) {
        final achievementId = 'glasses_$milestone';
        if (!_unlockedAchievements.contains(achievementId)) {
          await _unlockAchievement(achievementId);
          await _notificationService.showMilestoneAchievement(milestone);
        }
      }
    }
  }

  // Check daily goal achievement
  Future<void> checkDailyGoal(int currentIntake, int targetIntake) async {
    if (currentIntake >= targetIntake) {
      final today = DateTime.now();
      final achievementId = 'daily_${today.year}_${today.month}_${today.day}';

      if (!_unlockedAchievements.contains(achievementId)) {
        await _unlockAchievement(achievementId);
        await _notificationService.showGoalAchievedNotification();
      }
    }
  }

  // Check perfect week (all 7 days goals met)
  Future<void> checkPerfectWeek(List<bool> weeklyGoals) async {
    if (weeklyGoals.length == 7 && weeklyGoals.every((goal) => goal)) {
      final achievementId =
          'perfect_week_${DateTime.now().millisecondsSinceEpoch ~/ 604800000}';

      if (!_unlockedAchievements.contains(achievementId)) {
        await _unlockAchievement(achievementId);
        await _notificationService.showAchievementNotification(
          title: '⭐ Perfect Week!',
          body: 'You achieved your goal every single day this week!',
          payload: 'perfect_week',
        );
      }
    }
  }

  // Check early bird (logged water before 8 AM)
  Future<void> checkEarlyBird() async {
    final now = DateTime.now();
    if (now.hour < 8) {
      final achievementId = 'early_bird_${now.year}_${now.month}_${now.day}';

      if (!_unlockedAchievements.contains(achievementId)) {
        await _unlockAchievement(achievementId);
        await _notificationService.showAchievementNotification(
          title: '🌅 Early Bird!',
          body: 'Starting your day with hydration! Great job!',
          payload: 'early_bird',
        );
      }
    }
  }

  // Check night owl (still hydrating after 10 PM)
  Future<void> checkNightOwl() async {
    final now = DateTime.now();
    if (now.hour >= 22) {
      final achievementId = 'night_owl_${now.year}_${now.month}_${now.day}';

      if (!_unlockedAchievements.contains(achievementId)) {
        await _unlockAchievement(achievementId);
        await _notificationService.showAchievementNotification(
          title: '🌙 Night Owl!',
          body: 'Staying hydrated late! Don\'t forget rest too!',
          payload: 'night_owl',
        );
      }
    }
  }

  // Check overachiever (exceeded daily goal by 50%)
  Future<void> checkOverachiever(int currentIntake, int targetIntake) async {
    if (currentIntake >= targetIntake * 1.5) {
      final today = DateTime.now();
      final achievementId =
          'overachiever_${today.year}_${today.month}_${today.day}';

      if (!_unlockedAchievements.contains(achievementId)) {
        await _unlockAchievement(achievementId);
        await _notificationService.showAchievementNotification(
          title: '🚀 Overachiever!',
          body: 'You exceeded your daily goal by 50%! Amazing!',
          payload: 'overachiever',
        );
      }
    }
  }

  // Get all unlocked achievements
  Set<String> getUnlockedAchievements() {
    return Set.from(_unlockedAchievements);
  }

  // Check if specific achievement is unlocked
  bool isAchievementUnlocked(String achievementId) {
    return _unlockedAchievements.contains(achievementId);
  }

  // Get achievement progress
  Map<String, dynamic> getAchievementProgress({
    required int currentStreak,
    required int totalGlasses,
  }) {
    return {
      'streak_3': currentStreak >= 3,
      'streak_7': currentStreak >= 7,
      'streak_14': currentStreak >= 14,
      'streak_30': currentStreak >= 30,
      'streak_60': currentStreak >= 60,
      'streak_100': currentStreak >= 100,
      'glasses_50': totalGlasses >= 50,
      'glasses_100': totalGlasses >= 100,
      'glasses_250': totalGlasses >= 250,
      'glasses_500': totalGlasses >= 500,
      'glasses_1000': totalGlasses >= 1000,
    };
  }

  // Reset achievements (for testing or user request)
  Future<void> resetAchievements() async {
    _unlockedAchievements.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('unlocked_achievements');
  }
}
