class AnalyticsModel {
  final int totalIntake;
  final int targetIntake;
  final int daysTracked;
  final int currentStreak;
  final int longestStreak;
  final double averageDaily;
  final Map<String, int> weeklyData;
  final Map<String, int> monthlyData;
  final List<String> achievements;

  AnalyticsModel({
    required this.totalIntake,
    required this.targetIntake,
    required this.daysTracked,
    required this.currentStreak,
    required this.longestStreak,
    required this.averageDaily,
    required this.weeklyData,
    required this.monthlyData,
    required this.achievements,
  });

  double get completionRate {
    if (targetIntake == 0) return 0;
    return (totalIntake / targetIntake).clamp(0.0, 1.0);
  }

  String get performanceLevel {
    if (completionRate >= 1.0) {
      return 'Excellent';
    } else if (completionRate >= 0.8) {
      return 'Great';
    } else if (completionRate >= 0.6) {
      return 'Good';
    } else if (completionRate >= 0.4) {
      return 'Fair';
    } else {
      return 'Needs Improvement';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'totalIntake': totalIntake,
      'targetIntake': targetIntake,
      'daysTracked': daysTracked,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'averageDaily': averageDaily,
      'weeklyData': weeklyData,
      'monthlyData': monthlyData,
      'achievements': achievements,
    };
  }

  factory AnalyticsModel.fromMap(Map<String, dynamic> map) {
    return AnalyticsModel(
      totalIntake: map['totalIntake'] ?? 0,
      targetIntake: map['targetIntake'] ?? 0,
      daysTracked: map['daysTracked'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      averageDaily: (map['averageDaily'] ?? 0).toDouble(),
      weeklyData: Map<String, int>.from(map['weeklyData'] ?? {}),
      monthlyData: Map<String, int>.from(map['monthlyData'] ?? {}),
      achievements: List<String>.from(map['achievements'] ?? []),
    );
  }
}

class DailyStats {
  final DateTime date;
  final int intake;
  final int target;
  final List<IntakeEntry> entries;

  DailyStats({
    required this.date,
    required this.intake,
    required this.target,
    required this.entries,
  });

  double get completionRate => intake / target;
  bool get goalReached => intake >= target;

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'intake': intake,
      'target': target,
      'entries': entries.map((e) => e.toMap()).toList(),
    };
  }

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      date: DateTime.parse(map['date']),
      intake: map['intake'],
      target: map['target'],
      entries: (map['entries'] as List)
          .map((e) => IntakeEntry.fromMap(e))
          .toList(),
    );
  }
}

class IntakeEntry {
  final DateTime timestamp;
  final int milliliters;
  final String beverageType;

  IntakeEntry({
    required this.timestamp,
    required this.milliliters,
    required this.beverageType,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'milliliters': milliliters,
      'beverageType': beverageType,
    };
  }

  factory IntakeEntry.fromMap(Map<String, dynamic> map) {
    return IntakeEntry(
      timestamp: DateTime.parse(map['timestamp']),
      milliliters: map['milliliters'],
      beverageType: map['beverageType'],
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.isUnlocked,
    this.unlockedAt,
  });

  static List<Achievement> getDefaultAchievements() {
    return [
      Achievement(
        id: 'first_drop',
        title: 'First Drop',
        description: 'Started your hydration journey',
        iconName: 'medal',
        isUnlocked: false,
      ),
      Achievement(
        id: 'week_warrior',
        title: '7 Day Warrior',
        description: 'Maintained a 7-day streak',
        iconName: 'fire',
        isUnlocked: false,
      ),
      Achievement(
        id: 'month_master',
        title: 'Month Master',
        description: 'Reached your goal for 30 days',
        iconName: 'trophy',
        isUnlocked: false,
      ),
      Achievement(
        id: 'hydration_hero',
        title: 'Hydration Hero',
        description: 'Drank 100 liters total',
        iconName: 'star',
        isUnlocked: false,
      ),
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Drank water within 30 minutes of waking up for 7 days',
        iconName: 'sun',
        isUnlocked: false,
      ),
      Achievement(
        id: 'perfect_week',
        title: 'Perfect Week',
        description: 'Hit 100% of goal every day for a week',
        iconName: 'check_circle',
        isUnlocked: false,
      ),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      iconName: map['iconName'],
      isUnlocked: map['isUnlocked'],
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'])
          : null,
    );
  }
}
