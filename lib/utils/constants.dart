class AppConstants {
  static const String appName = 'H2Orbit';
  static const int defaultWaterTarget = 8; // glasses
  static const int mlPerGlass = 250;

  // Beverage types
  static const Map<String, double> beverageMultipliers = {
    'water': 1.0,
    'juice': 0.9,
    'tea': 0.8,
    'coffee': 0.7,
    'soda': 0.6,
    'milk': 0.85,
  };

  // Caffeine offset (ml to subtract per mg of caffeine)
  static const double caffeineOffset = 1.5;
}
