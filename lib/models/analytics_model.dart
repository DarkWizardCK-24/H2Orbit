import 'package:h2orbit/domain/hydration_math.dart';
import 'package:h2orbit/domain/streaks.dart';
import 'package:h2orbit/models/water_intake_model.dart';
import 'package:h2orbit/utils/helpers.dart';

/// Total drunk on one calendar day.
class DayTotal {
  final DateTime day;
  final int ml;
  final bool isToday;
  final bool isFuture;

  const DayTotal({
    required this.day,
    required this.ml,
    required this.isToday,
    required this.isFuture,
  });
}

enum DayPart {
  morning('Morning', '5 am - 12 pm'),
  afternoon('Afternoon', '12 - 5 pm'),
  evening('Evening', '5 - 9 pm'),
  night('Night', '9 pm - 5 am');

  final String label;
  final String range;

  const DayPart(this.label, this.range);

  static DayPart of(DateTime time) {
    final h = time.hour;
    if (h >= 5 && h < 12) return DayPart.morning;
    if (h >= 12 && h < 17) return DayPart.afternoon;
    if (h >= 17 && h < 21) return DayPart.evening;
    return DayPart.night;
  }
}

/// Everything the analytics screen shows, computed from one list of intakes.
class AnalyticsSummary {
  final int goalMl;

  /// Monday to Sunday of the current week.
  final List<DayTotal> week;

  /// The last 30 days, oldest first, ending today.
  final List<DayTotal> last30;

  final int monthTotalMl;
  final int monthDaysElapsed;
  final int currentStreak;
  final int longestStreak;
  final int goalDaysThisWeek;
  final int goalDaysLast30;

  /// Volume per beverage type over the last 30 days.
  final Map<String, int> byBeverage;

  /// Volume per part of the day over the last 30 days.
  final Map<DayPart, int> byDayPart;

  /// Highest single-day total as a fraction of the goal (1.5 = 150 %).
  final double bestDayRatio;

  /// Days with a drink logged before 8 am.
  final int earlyBirdDays;

  const AnalyticsSummary({
    required this.goalMl,
    required this.week,
    required this.last30,
    required this.monthTotalMl,
    required this.monthDaysElapsed,
    required this.currentStreak,
    required this.longestStreak,
    required this.goalDaysThisWeek,
    required this.goalDaysLast30,
    required this.byBeverage,
    required this.byDayPart,
    required this.bestDayRatio,
    required this.earlyBirdDays,
  });

  factory AnalyticsSummary.from(
    Iterable<WaterIntakeModel> intakes, {
    required int goalMl,
    required DateTime now,
  }) {
    final today = Dates.startOfDay(now);
    final totals = HydrationMath.totalsByDay(intakes);

    DayTotal dayTotal(DateTime day) => DayTotal(
      day: day,
      ml: totals[day] ?? 0,
      isToday: day == today,
      isFuture: day.isAfter(today),
    );

    final weekStart = Dates.startOfWeek(today);
    final week = [
      for (var i = 0; i < 7; i++) dayTotal(Dates.addDays(weekStart, i)),
    ];
    final last30 = [
      for (var i = 29; i >= 0; i--) dayTotal(Dates.addDays(today, -i)),
    ];

    final monthStart = Dates.startOfMonth(today);
    var monthTotal = 0;
    totals.forEach((day, ml) {
      if (!day.isBefore(monthStart) && !day.isAfter(today)) monthTotal += ml;
    });

    final windowStart = last30.first.day;
    final byBeverage = <String, int>{};
    final byDayPart = <DayPart, int>{};
    final earlyBirdDates = <DateTime>{};
    for (final intake in intakes) {
      final day = Dates.startOfDay(intake.timestamp);
      if (intake.timestamp.hour < 8) earlyBirdDates.add(day);
      if (day.isBefore(windowStart) || day.isAfter(today)) continue;
      byBeverage[intake.beverageType] =
          (byBeverage[intake.beverageType] ?? 0) + intake.milliliters;
      final part = DayPart.of(intake.timestamp);
      byDayPart[part] = (byDayPart[part] ?? 0) + intake.milliliters;
    }

    final bestMl = totals.values.fold<int>(0, (a, b) => a > b ? a : b);

    return AnalyticsSummary(
      goalMl: goalMl,
      week: week,
      last30: last30,
      monthTotalMl: monthTotal,
      monthDaysElapsed: today.day,
      currentStreak: StreakCalculator.current(
        totals,
        goalMl: goalMl,
        today: today,
      ),
      longestStreak: StreakCalculator.longest(totals, goalMl: goalMl),
      goalDaysThisWeek: week.where((d) => !d.isFuture && d.ml >= goalMl).length,
      goalDaysLast30: last30.where((d) => d.ml >= goalMl).length,
      byBeverage: byBeverage,
      byDayPart: byDayPart,
      bestDayRatio: goalMl > 0 ? bestMl / goalMl : 0,
      earlyBirdDays: earlyBirdDates.length,
    );
  }

  int get weekTotalMl => week.fold(0, (sum, d) => sum + d.ml);

  bool get weekHasData => week.any((d) => d.ml > 0);

  /// Average per day so far this month.
  int get dailyAverageMl =>
      monthDaysElapsed == 0 ? 0 : (monthTotalMl / monthDaysElapsed).round();

  /// Day with the most water this week (earliest wins a tie).
  DayTotal? get bestDayThisWeek {
    DayTotal? best;
    for (final d in week) {
      if (d.ml > 0 && (best == null || d.ml > best.ml)) best = d;
    }
    return best;
  }

  /// Part of the day with the most water over the last 30 days.
  DayPart? get topDayPart {
    DayPart? top;
    var topMl = 0;
    byDayPart.forEach((part, ml) {
      if (ml > topMl) {
        top = part;
        topMl = ml;
      }
    });
    return top;
  }

  /// Days in the last 30 on which anything was logged.
  int get daysTracked30 => last30.where((d) => d.ml > 0).length;
}
