import 'package:flutter_test/flutter_test.dart';
import 'package:h2orbit/domain/achievements.dart';
import 'package:h2orbit/domain/hydration_math.dart';
import 'package:h2orbit/domain/streaks.dart';
import 'package:h2orbit/domain/trend_insights.dart';
import 'package:h2orbit/models/analytics_model.dart';
import 'package:h2orbit/models/user_model.dart';
import 'package:h2orbit/services/ai_prediction_service.dart';
import 'package:h2orbit/services/auth_service.dart';
import 'package:h2orbit/services/notification_service.dart';
import 'package:h2orbit/services/weather_service.dart';
import 'package:h2orbit/utils/helpers.dart';

import 'support/fakes.dart';

/// Wednesday 14 Oct 2026, so this week runs Mon 12 Oct - Sun 18 Oct.
final DateTime now = DateTime(2026, 10, 14, 15, 30);
DateTime day(int offset) => Dates.addDays(Dates.startOfDay(now), offset);

void main() {
  group('HydrationMath', () {
    test('recommended intake adjusts for weight, age and gender', () {
      expect(
        HydrationMath.recommendedDailyMl(
          weightKg: 70,
          age: 30,
          gender: 'Other',
        ),
        2450,
      );
      expect(
        HydrationMath.recommendedDailyMl(weightKg: 70, age: 30, gender: 'Male'),
        2573, // 2450 * 1.05
      );
      expect(
        HydrationMath.recommendedDailyMl(
          weightKg: 70,
          age: 70,
          gender: 'Other',
        ),
        2205, // 2450 * 0.9
      );
    });

    test('recommended glasses stay inside the allowed range', () {
      expect(
        HydrationMath.recommendedGlasses(
          weightKg: 30,
          age: 30,
          gender: 'Other',
        ),
        4,
      );
      expect(
        HydrationMath.recommendedGlasses(
          weightKg: 200,
          age: 30,
          gender: 'Male',
        ),
        16,
      );
      expect(
        HydrationMath.recommendedGlasses(
          weightKg: 70,
          age: 30,
          gender: 'Other',
        ),
        10,
      );
    });

    test('hot weather adds water', () {
      expect(HydrationMath.weatherBonusMl(20), 0);
      expect(HydrationMath.weatherBonusMl(26), 500);
      expect(HydrationMath.weatherBonusMl(31), 750);
      expect(HydrationMath.weatherBonusMl(36), 1000);
    });

    test('BMI and category', () {
      final bmi = HydrationMath.bmi(weightKg: 70, heightCm: 175);
      expect(bmi, closeTo(22.9, 0.05));
      expect(HydrationMath.bmiCategory(bmi), 'Healthy');
      expect(HydrationMath.bmiCategory(17), 'Underweight');
      expect(HydrationMath.bmiCategory(27), 'Overweight');
      expect(HydrationMath.bmiCategory(32), 'Obese');
    });

    test('totalsByDay groups by calendar day', () {
      final totals = HydrationMath.totalsByDay([
        drink(DateTime(2026, 10, 14, 8), 250),
        drink(DateTime(2026, 10, 14, 23, 59), 500),
        drink(DateTime(2026, 10, 15, 0, 1), 300),
      ]);
      expect(totals[DateTime(2026, 10, 14)], 750);
      expect(totals[DateTime(2026, 10, 15)], 300);
    });

    test('caffeine is estimated from coffee and tea volume', () {
      final mg = HydrationMath.caffeineMg([
        drink(now, 150, type: 'coffee'), // ~95 mg
        drink(now, 150, type: 'tea'), // ~41 mg
        drink(now, 500), // water: none
      ]);
      expect(mg, inInclusiveRange(130, 140));
    });
  });

  group('StreakCalculator', () {
    const goal = 2000;

    test('counts consecutive goal days ending today', () {
      final totals = {
        day(0): 2100,
        day(-1): 2000,
        day(-2): 2500,
        day(-4): 3000,
      };
      expect(
        StreakCalculator.current(totals, goalMl: goal, today: now),
        3, // the gap on day -3 ends the run
      );
    });

    test("today not reached yet doesn't break the streak", () {
      final totals = {day(0): 500, day(-1): 2000, day(-2): 2000};
      expect(StreakCalculator.current(totals, goalMl: goal, today: now), 2);
    });

    test('a missed yesterday ends the streak', () {
      final totals = {day(0): 500, day(-1): 1900, day(-2): 2000};
      expect(StreakCalculator.current(totals, goalMl: goal, today: now), 0);
    });

    test('a few sips alone do not make a streak day', () {
      final totals = {for (var i = 0; i < 10; i++) day(-i): 100};
      expect(StreakCalculator.current(totals, goalMl: goal, today: now), 0);
    });

    test('longest streak is found anywhere in the history', () {
      final totals = {
        day(-20): 2000,
        day(-19): 2000,
        day(-18): 2000,
        day(-17): 2000,
        day(-5): 2000,
        day(-4): 2000,
        day(0): 2000,
      };
      expect(StreakCalculator.longest(totals, goalMl: goal), 4);
    });

    test('streaks survive a daylight-saving change', () {
      // 2026-03-29 is when Europe springs forward (a 23-hour day).
      final today = DateTime(2026, 3, 30, 12);
      final totals = {
        DateTime(2026, 3, 30): 2000,
        DateTime(2026, 3, 29): 2000,
        DateTime(2026, 3, 28): 2000,
      };
      expect(StreakCalculator.current(totals, goalMl: goal, today: today), 3);
    });
  });

  group('AnalyticsSummary', () {
    final intakes = [
      // This week (Mon 12 Oct - Sun 18 Oct)
      drink(DateTime(2026, 10, 12, 7, 30), 500), // early bird, Monday
      drink(DateTime(2026, 10, 12, 13), 1600, type: 'coffee'),
      drink(DateTime(2026, 10, 13, 9), 2000),
      drink(DateTime(2026, 10, 14, 14), 750), // today
      // Earlier
      drink(DateTime(2026, 10, 9, 10), 3200), // 160 % of goal
      drink(DateTime(2026, 9, 20, 10), 1000),
    ];
    final s = AnalyticsSummary.from(intakes, goalMl: 2000, now: now);

    test('builds Monday to Sunday with today and future flagged', () {
      expect(s.week.map((d) => d.day.weekday), [1, 2, 3, 4, 5, 6, 7]);
      expect(s.week[0].ml, 2100);
      expect(s.week[1].ml, 2000);
      expect(s.week[2].ml, 750);
      expect(s.week[2].isToday, isTrue);
      expect(s.week[3].isFuture, isTrue);
      expect(s.weekTotalMl, 4850);
      expect(s.goalDaysThisWeek, 2);
    });

    test('month totals only include this month up to today', () {
      expect(s.monthTotalMl, 3200 + 2100 + 2000 + 750);
      expect(s.monthDaysElapsed, 14);
      expect(s.dailyAverageMl, (8050 / 14).round());
    });

    test('best day this week', () {
      expect(s.bestDayThisWeek!.day, day(-2));
    });

    test('streaks use the goal', () {
      // Mon 2100 and Tue 2000 reached it; today (750) is still in progress
      // so it neither counts nor breaks the streak.
      expect(s.currentStreak, 2);
      expect(s.longestStreak, 2);
    });

    test('last 30 days window and breakdowns', () {
      expect(s.last30.length, 30);
      expect(s.last30.last.isToday, isTrue);
      expect(s.byBeverage['coffee'], 1600);
      expect(
        s.topDayPart,
        DayPart.morning,
      ); // 6700 ml vs 2350 ml in the afternoon
      expect(s.bestDayRatio, 1.6);
      expect(s.earlyBirdDays, 1);
    });

    test('empty data is safe', () {
      final empty = AnalyticsSummary.from(const [], goalMl: 2000, now: now);
      expect(empty.weekHasData, isFalse);
      expect(empty.dailyAverageMl, 0);
      expect(empty.bestDayThisWeek, isNull);
      expect(empty.topDayPart, isNull);
      expect(TrendInsights.observations(empty), isEmpty);
      expect(TrendInsights.suggestions(empty), isNotEmpty);
    });
  });

  group('Achievements', () {
    test('are derived from the data', () {
      final strong = AnalyticsSummary.from(
        [
          for (var i = 0; i < 8; i++)
            drink(Dates.addDays(DateTime(2026, 10, 14, 7), -i), 3200),
        ],
        goalMl: 2000,
        now: now,
      );
      final unlocked = AchievementCatalog.unlocked(strong, allTimeMl: 25000);
      expect(unlocked, containsAll(['first_sip', 'streak_3', 'streak_7']));
      expect(
        unlocked,
        containsAll(['glasses_100', 'overachiever', 'early_bird']),
      );
      expect(unlocked, isNot(contains('streak_30')));
      expect(unlocked, isNot(contains('glasses_500')));

      final none = AnalyticsSummary.from(const [], goalMl: 2000, now: now);
      expect(AchievementCatalog.unlocked(none, allTimeMl: 0), isEmpty);
    });
  });

  group('HydrationCoach', () {
    test('expected progress follows the waking day', () {
      expect(HydrationCoach.expectedProgress(DateTime(2026, 1, 1, 5)), 0);
      expect(
        HydrationCoach.expectedProgress(DateTime(2026, 1, 1, 14, 30)),
        0.5,
      );
      expect(HydrationCoach.expectedProgress(DateTime(2026, 1, 1, 23)), 1);
    });

    test('warns when well behind schedule and says how much to drink', () {
      final tips = HydrationCoach.tips(
        intakeMl: 250,
        goalMl: 2000,
        now: DateTime(2026, 10, 14, 15),
      );
      expect(tips.first.kind, TipKind.warning);
      expect(tips.first.message, contains('ml'));
    });

    test('celebrates a reached goal first', () {
      final tips = HydrationCoach.tips(
        intakeMl: 2100,
        goalMl: 2000,
        now: DateTime(2026, 10, 14, 15),
      );
      expect(tips.first.title, 'Goal reached');
    });

    test('mentions heat and caffeine and a low goal', () {
      final tips = HydrationCoach.tips(
        intakeMl: 1000,
        goalMl: 2000,
        now: DateTime(2026, 10, 14, 15),
        user: sampleUser(glasses: 4, weightKg: 90),
        caffeineMg: 300,
        weather: const WeatherSnapshot(
          temperatureC: 33,
          feelsLikeC: 36,
          humidity: 60,
          description: 'sunny',
          iconCode: '01d',
          city: 'Pune',
        ),
      );
      final titles = tips.map((t) => t.title).join('|');
      expect(titles, contains('Hot day in Pune'));
      expect(titles, contains('Lots of caffeine'));
      expect(titles, contains('goal looks low'));
    });

    test('is deterministic and never empty', () {
      final a = HydrationCoach.tips(intakeMl: 0, goalMl: 2000, now: now);
      final b = HydrationCoach.tips(intakeMl: 0, goalMl: 2000, now: now);
      expect(a.map((t) => t.title), b.map((t) => t.title));
      expect(a, isNotEmpty);
    });
  });

  group('ReminderPlanner', () {
    test('lists times in the window', () {
      expect(
        ReminderPlanner.slots(
          startMinutes: 480,
          endMinutes: 720,
          intervalHours: 2,
        ),
        [480, 600, 720],
      );
    });

    test('rejects an empty or backwards window', () {
      expect(
        ReminderPlanner.slots(
          startMinutes: 600,
          endMinutes: 480,
          intervalHours: 2,
        ),
        isEmpty,
      );
      expect(
        ReminderPlanner.slots(
          startMinutes: 480,
          endMinutes: 720,
          intervalHours: 0,
        ),
        isEmpty,
      );
    });

    test('caps the number of reminders a day', () {
      expect(
        ReminderPlanner.slots(
          startMinutes: 0,
          endMinutes: 1439,
          intervalHours: 1,
        ).length,
        24,
      );
    });
  });

  group('Misc', () {
    test('auth errors map to friendly messages', () {
      expect(
        AuthFailure.fromCode('invalid-credential').message,
        'Incorrect email or password.',
      );
      expect(
        AuthFailure.fromCode('email-already-in-use').message,
        contains('already registered'),
      );
      expect(
        AuthFailure.fromCode('???').message,
        contains('Something went wrong'),
      );
    });

    test('formatting helpers', () {
      expect(Fmt.ml(1250), '1,250 ml');
      expect(Fmt.liters(2000), '2 L');
      expect(Fmt.liters(1250), '1.3 L');
      expect(Fmt.glasses(375), '1.5');
      expect(Fmt.glasses(500), '2');
      expect(Fmt.greeting(DateTime(2026, 1, 1, 9)), 'Good morning');
      expect(Fmt.greeting(DateTime(2026, 1, 1, 22)), 'Good night');
    });

    test('weeks start on Monday', () {
      expect(Dates.startOfWeek(DateTime(2026, 10, 18)), DateTime(2026, 10, 12));
      expect(Dates.startOfWeek(DateTime(2026, 10, 12)), DateTime(2026, 10, 12));
    });

    test('age calculation honours the birthday', () {
      final dob = DateTime(2000, 6, 15);
      expect(UserModel.calculateAge(dob, now: DateTime(2026, 6, 14)), 25);
      expect(UserModel.calculateAge(dob, now: DateTime(2026, 6, 15)), 26);
    });

    test('validators', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.phone('+91 98765 43210'), isNull);
      expect(Validators.phone('12345'), isNotNull);
    });

    test('weather json is parsed', () {
      final w = WeatherSnapshot.fromJson({
        'main': {'temp': 31.2, 'feels_like': 35, 'humidity': 70},
        'weather': [
          {'description': 'haze', 'icon': '50d'},
        ],
        'name': 'Pune',
      });
      expect(w.city, 'Pune');
      expect(w.bonusMl, 750);
      expect(w.isHot, isTrue);
    });
  });
}
