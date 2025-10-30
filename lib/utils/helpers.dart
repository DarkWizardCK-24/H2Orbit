import 'package:intl/intl.dart';

class Helpers {
  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format time
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  // Format date and time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  // Get time ago
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays >= 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays >= 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Convert ml to liters
  static String mlToLiters(int ml) {
    return (ml / 1000).toStringAsFixed(2);
  }

  // Convert ml to glasses (250ml per glass)
  static String mlToGlasses(int ml) {
    return (ml / 250).toStringAsFixed(1);
  }

  // Calculate BMI
  static double calculateBMI(int weightKg, int heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  // Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  // Calculate daily water requirement (in ml)
  static int calculateDailyRequirement(int weightKg, int age, String gender) {
    // Base calculation: 35ml per kg of body weight
    double baseRequirement = weightKg * 35;

    // Adjust for age
    if (age < 18) {
      baseRequirement *= 1.1;
    } else if (age > 65) {
      baseRequirement *= 0.9;
    }

    // Adjust for gender
    if (gender.toLowerCase() == 'male') {
      baseRequirement *= 1.05;
    } else if (gender.toLowerCase() == 'female') {
      baseRequirement *= 0.95;
    }

    return baseRequirement.toInt();
  }

  // Get hydration level
  static String getHydrationLevel(int current, int target) {
    final percentage = (current / target * 100).toInt();

    if (percentage >= 100) {
      return 'Excellent';
    } else if (percentage >= 80) {
      return 'Good';
    } else if (percentage >= 50) {
      return 'Fair';
    } else if (percentage >= 25) {
      return 'Low';
    } else {
      return 'Critical';
    }
  }

  // Get motivational message based on progress
  static String getMotivationalMessage(double progress) {
    if (progress >= 1.0) {
      return 'Amazing! You\'re crushing your hydration goals! 🎉';
    } else if (progress >= 0.8) {
      return 'Almost there! Keep up the great work! 💪';
    } else if (progress >= 0.6) {
      return 'You\'re doing great! Stay consistent! 👍';
    } else if (progress >= 0.4) {
      return 'Good start! Let\'s boost that hydration! 🚀';
    } else if (progress >= 0.2) {
      return 'Time to drink up! Your body needs water! 💧';
    } else {
      return 'Let\'s get started! Every sip counts! 🌊';
    }
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone.replaceAll(' ', ''));
  }

  // Get greeting based on time
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else if (hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  // Get day of week
  static String getDayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Get week start date
  static DateTime getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // Get month start date
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Format percentage
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  // Get hydration color based on percentage
  static String getHydrationColor(double percentage) {
    if (percentage >= 1.0) {
      return '#4CAF50'; // Green
    } else if (percentage >= 0.75) {
      return '#8BC34A'; // Light Green
    } else if (percentage >= 0.5) {
      return '#FFC107'; // Amber
    } else if (percentage >= 0.25) {
      return '#FF9800'; // Orange
    } else {
      return '#F44336'; // Red
    }
  }
}