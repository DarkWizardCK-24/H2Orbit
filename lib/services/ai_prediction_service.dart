import 'dart:math';
import 'package:h2orbit/models/user_model.dart';

class AIPredictionService {
  static Future<String> getPrediction(
    UserModel? user,
    int currentIntake,
    int targetIntake,
  ) async {
    if (user == null) {
      return 'Stay hydrated! Drink water regularly throughout the day.';
    }

    final progress = currentIntake / targetIntake;
    final hour = DateTime.now().hour;
    final predictions = <String>[];

    // Time-based predictions
    if (hour < 12 && progress < 0.3) {
      predictions.add(
        'Morning boost needed! Start your day with 2 glasses of water to kickstart your metabolism.',
      );
    } else if (hour >= 12 && hour < 17 && progress < 0.5) {
      predictions.add(
        'Afternoon energy dip? Dehydration might be the culprit. Have a glass of water now!',
      );
    } else if (hour >= 17 && hour < 21 && progress < 0.7) {
      predictions.add(
        'Evening hydration is key! Aim to reach 80% of your goal before bedtime.',
      );
    } else if (hour >= 21 && progress < 0.8) {
      predictions.add(
        'Almost there! One or two more glasses will help you reach your daily goal.',
      );
    }

    // Progress-based predictions
    if (progress >= 1.0) {
      predictions.add(
        '🎉 Amazing! You\'ve reached your goal! Keep this consistency for optimal health.',
      );
    } else if (progress >= 0.8) {
      predictions.add(
        '💪 You\'re so close! Just ${((targetIntake - currentIntake) / 250).ceil()} more glass(es) to go!',
      );
    } else if (progress >= 0.5) {
      predictions.add('👍 Great progress! You\'re halfway there. Keep it up!');
    } else if (progress >= 0.25) {
      predictions.add(
        '🚀 Good start! Let\'s aim for ${((targetIntake * 0.5).toInt() / 250).ceil()} glasses by noon.',
      );
    } else {
      predictions.add(
        '💧 Let\'s get hydrated! Small sips throughout the day make a big difference.',
      );
    }

    // Weight-based recommendations
    final recommendedDaily = _calculateRecommendedIntake(
      user.weightKg,
      user.heightCm,
      user.age,
      user.gender,
    );

    if (targetIntake < recommendedDaily * 0.8) {
      predictions.add(
        'Based on your body metrics, consider increasing your daily target to ${(recommendedDaily / 250).ceil()} glasses.',
      );
    }

    // Activity-based (simulated)
    if (hour >= 6 && hour < 9) {
      predictions.add(
        'Morning routine? Drink water before your coffee or tea for better hydration absorption.',
      );
    } else if (hour >= 12 && hour < 14) {
      predictions.add(
        'Lunchtime! Drink a glass of water 30 minutes before your meal for better digestion.',
      );
    } else if (hour >= 18 && hour < 20) {
      predictions.add(
        'Post-work hydration helps reduce stress and improves evening focus.',
      );
    }

    // Motivational messages
    final motivational = [
      'Water is the driving force of all nature. - Leonardo da Vinci',
      'Your body is 60% water. Keep it well-maintained!',
      'Hydration = Better focus + More energy + Glowing skin',
      'Small sips, big impact. Every drop counts!',
      'Your future self will thank you for staying hydrated today.',
    ];

    if (Random().nextDouble() > 0.7) {
      predictions.add(motivational[Random().nextInt(motivational.length)]);
    }

    return predictions.isNotEmpty
        ? predictions[Random().nextInt(predictions.length)]
        : 'Keep drinking water regularly!';
  }

  static int _calculateRecommendedIntake(
    int weight,
    int height,
    int age,
    String gender,
  ) {
    // Base calculation: weight (kg) * 35ml
    double baseIntake = weight * 35;

    // Adjust for gender
    if (gender.toLowerCase() == 'male') {
      baseIntake *= 1.05;
    }

    // Adjust for age
    if (age > 50) {
      baseIntake *= 0.95;
    } else if (age < 25) {
      baseIntake *= 1.05;
    }

    return baseIntake.toInt();
  }

  static String getWeatherBasedRecommendation(double temperature) {
    if (temperature > 30) {
      return 'Hot weather alert! Increase water intake by 20% to prevent dehydration.';
    } else if (temperature > 25) {
      return 'Warm day ahead! Remember to drink extra water if you\'re outdoors.';
    } else if (temperature < 15) {
      return 'Cool weather doesn\'t mean less hydration! Keep sipping water.';
    }
    return 'Perfect weather for outdoor activities! Stay hydrated.';
  }

  static String getActivityBasedRecommendation(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'high':
        return 'High activity detected! Aim for 15-20% more water than usual.';
      case 'medium':
        return 'Moderate activity! Add 2-3 extra glasses to your daily goal.';
      case 'low':
        return 'Even on rest days, maintain your hydration routine.';
      default:
        return 'Regular hydration is key to optimal health.';
    }
  }

  static List<String> getPersonalizedTips(UserModel user) {
    final tips = <String>[];

    // Age-based tips
    if (user.age < 25) {
      tips.add('Young bodies need consistent hydration for peak performance!');
    } else if (user.age > 50) {
      tips.add(
        'Hydration becomes even more important with age. Set regular reminders!',
      );
    }

    // Gender-based tips
    if (user.gender.toLowerCase() == 'female') {
      tips.add(
        'Women need about 2.7L per day. Track your intake consistently!',
      );
    } else if (user.gender.toLowerCase() == 'male') {
      tips.add(
        'Men need about 3.7L per day. Stay ahead of your hydration game!',
      );
    }

    // BMI-based tips
    final bmi = user.weightKg / pow(user.heightCm / 100, 2);
    if (bmi > 25) {
      tips.add(
        'Higher body mass requires more water. Adjust your target accordingly!',
      );
    }

    return tips;
  }

  static String getCaffeineOffsetAdvice(int caffeineIntakeMg) {
    if (caffeineIntakeMg > 400) {
      return 'High caffeine intake! Drink an extra ${(caffeineIntakeMg * 0.5 / 250).ceil()} glasses of water to compensate.';
    } else if (caffeineIntakeMg > 200) {
      return 'Moderate caffeine detected. Add 1-2 extra glasses of water today.';
    } else if (caffeineIntakeMg > 0) {
      return 'Balance your coffee with water for optimal hydration.';
    }
    return 'No caffeine today? Great! Your hydration is on track.';
  }
}
