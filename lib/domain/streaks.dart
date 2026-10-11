import 'package:h2orbit/utils/helpers.dart';

/// A "streak day" is a day on which the daily goal was reached.
class StreakCalculator {
  StreakCalculator._();

  /// Consecutive goal days ending today.
  ///
  /// If today's goal isn't reached *yet*, the streak is not broken: it simply
  /// continues from yesterday until the day is over.
  static int current(
    Map<DateTime, int> totalsByDay, {
    required int goalMl,
    required DateTime today,
  }) {
    if (goalMl <= 0) return 0;

    var day = Dates.startOfDay(today);
    if ((totalsByDay[day] ?? 0) < goalMl) {
      day = Dates.addDays(day, -1);
    }

    var streak = 0;
    while ((totalsByDay[day] ?? 0) >= goalMl) {
      streak++;
      day = Dates.addDays(day, -1);
    }
    return streak;
  }

  /// Longest run of consecutive goal days anywhere in [totalsByDay].
  static int longest(Map<DateTime, int> totalsByDay, {required int goalMl}) {
    if (goalMl <= 0) return 0;

    final goalDays =
        totalsByDay.entries
            .where((e) => e.value >= goalMl)
            .map((e) => Dates.startOfDay(e.key))
            .toList()
          ..sort();

    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final day in goalDays) {
      if (previous != null && Dates.addDays(previous, 1) == day) {
        run++;
      } else {
        run = 1;
      }
      if (run > best) best = run;
      previous = day;
    }
    return best;
  }
}
