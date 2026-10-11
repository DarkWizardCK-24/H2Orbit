import 'package:h2orbit/models/beverage_model.dart';
import 'package:h2orbit/models/water_intake_model.dart';
import 'package:h2orbit/utils/constants.dart';
import 'package:h2orbit/utils/helpers.dart';

/// Pure hydration formulas. No Flutter, no Firebase, so they are easy to test.
class HydrationMath {
  HydrationMath._();

  /// Daily water need in ml: ~35 ml per kg, adjusted for age and gender.
  static int recommendedDailyMl({
    required int weightKg,
    required int age,
    required String gender,
  }) {
    double ml = weightKg * 35.0;
    if (age < 18) {
      ml *= 1.1;
    } else if (age > 65) {
      ml *= 0.9;
    }
    switch (gender.toLowerCase()) {
      case 'male':
        ml *= 1.05;
      case 'female':
        ml *= 0.95;
    }
    return ml.round();
  }

  /// [recommendedDailyMl] as glasses, kept inside the range the app allows.
  static int recommendedGlasses({
    required int weightKg,
    required int age,
    required String gender,
  }) {
    final glasses =
        recommendedDailyMl(weightKg: weightKg, age: age, gender: gender) /
        AppConstants.mlPerGlass;
    return glasses.round().clamp(
      AppConstants.minGlassTarget,
      AppConstants.maxGlassTarget,
    );
  }

  /// Extra water to drink on a hot day, rounded to a sensible amount.
  static int weatherBonusMl(double temperatureC) {
    if (temperatureC > 35) return 1000;
    if (temperatureC > 30) return 750;
    if (temperatureC > 25) return 500;
    return 0;
  }

  static double bmi({required int weightKg, required int heightCm}) {
    final meters = heightCm / 100;
    return weightKg / (meters * meters);
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Total volume per calendar day (keys are local midnights).
  static Map<DateTime, int> totalsByDay(Iterable<WaterIntakeModel> intakes) {
    final totals = <DateTime, int>{};
    for (final intake in intakes) {
      final day = Dates.startOfDay(intake.timestamp);
      totals[day] = (totals[day] ?? 0) + intake.milliliters;
    }
    return totals;
  }

  /// Caffeine drunk, estimated from the type and volume of each drink.
  static int caffeineMg(Iterable<WaterIntakeModel> intakes) {
    double mg = 0;
    for (final intake in intakes) {
      final per100 = BeverageModel.caffeineMgPer100ml[intake.beverageType] ?? 0;
      mg += intake.milliliters * per100 / 100;
    }
    return mg.round();
  }
}
