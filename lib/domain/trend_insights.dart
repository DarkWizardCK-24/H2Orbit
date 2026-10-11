import 'package:flutter/material.dart';
import 'package:h2orbit/models/analytics_model.dart';
import 'package:h2orbit/services/ai_prediction_service.dart';
import 'package:h2orbit/utils/helpers.dart';

/// Observations and suggestions drawn from the last 30 days of data.
class TrendInsights {
  TrendInsights._();

  static List<CoachTip> observations(AnalyticsSummary s) {
    final result = <CoachTip>[];
    final tracked = s.daysTracked30;
    if (tracked == 0) return result;

    final totalMl = s.last30.fold<int>(0, (sum, d) => sum + d.ml);
    final avg = (totalMl / tracked).round();
    result.add(
      CoachTip(
        kind: TipKind.info,
        title: 'Average on days you log',
        message:
            '${Fmt.ml(avg)} a day, about ${Fmt.glasses(avg)} glasses, over '
            '$tracked tracked ${tracked == 1 ? 'day' : 'days'}.',
        icon: Icons.water_drop_rounded,
        priority: 0,
      ),
    );

    result.add(
      CoachTip(
        kind: s.goalDaysLast30 >= 20 ? TipKind.success : TipKind.info,
        title: 'Goal days',
        message:
            'You reached your goal on ${s.goalDaysLast30} of the last 30 days.',
        icon: Icons.flag_rounded,
        priority: 1,
      ),
    );

    final part = s.topDayPart;
    if (part != null) {
      final partMl = s.byDayPart[part] ?? 0;
      final share = totalMl == 0 ? 0 : (partMl / totalMl * 100).round();
      result.add(
        CoachTip(
          kind: TipKind.info,
          title: 'Most active in the ${part.label.toLowerCase()}',
          message: '$share% of your drinks are between ${part.range}.',
          icon: Icons.schedule_rounded,
          priority: 2,
        ),
      );
    }
    return result;
  }

  static List<CoachTip> suggestions(AnalyticsSummary s) {
    final result = <CoachTip>[];
    final tracked = s.daysTracked30;

    if (tracked < 20) {
      result.add(
        const CoachTip(
          kind: TipKind.info,
          title: 'Log more consistently',
          message:
              'You logged on fewer than 20 of the last 30 days. A daily '
              'reminder can help build the habit.',
          icon: Icons.notifications_active_rounded,
          priority: 0,
        ),
      );
    }

    final total = s.byBeverage.values.fold<int>(0, (a, b) => a + b);
    final caffeinated =
        (s.byBeverage['coffee'] ?? 0) + (s.byBeverage['tea'] ?? 0);
    if (total > 0 && caffeinated / total > 0.3) {
      result.add(
        CoachTip(
          kind: TipKind.info,
          title: 'A lot of tea and coffee',
          message:
              'They make up ${(caffeinated / total * 100).round()}% of what '
              'you drink. Try alternating each cup with a glass of water.',
          icon: Icons.coffee_rounded,
          priority: 1,
        ),
      );
    }

    final evening =
        (s.byDayPart[DayPart.evening] ?? 0) + (s.byDayPart[DayPart.night] ?? 0);
    final morning = s.byDayPart[DayPart.morning] ?? 0;
    final dayTotal = s.byDayPart.values.fold<int>(0, (a, b) => a + b);
    if (dayTotal > 0 && morning / dayTotal < 0.2) {
      result.add(
        const CoachTip(
          kind: TipKind.info,
          title: 'Drink more in the morning',
          message:
              'Less than a fifth of your water is before noon. Start the day '
              'with a glass to catch up earlier.',
          icon: Icons.wb_twilight_rounded,
          priority: 2,
        ),
      );
    } else if (dayTotal > 0 && evening / dayTotal > 0.5) {
      result.add(
        const CoachTip(
          kind: TipKind.info,
          title: 'Spread your drinks out',
          message:
              'Over half of your water comes in the evening. Sipping earlier '
              'in the day is easier on sleep.',
          icon: Icons.bedtime_rounded,
          priority: 2,
        ),
      );
    }

    if (s.goalDaysLast30 >= 25) {
      result.add(
        const CoachTip(
          kind: TipKind.success,
          title: 'Excellent consistency',
          message: 'You are hitting your goal almost every day. Great habit!',
          icon: Icons.emoji_events_rounded,
          priority: 3,
        ),
      );
    }

    if (result.isEmpty) {
      result.add(
        const CoachTip(
          kind: TipKind.info,
          title: 'Keep it up',
          message: 'Your habits look balanced. Keep logging every day.',
          icon: Icons.thumb_up_alt_rounded,
          priority: 9,
        ),
      );
    }
    return result;
  }
}
