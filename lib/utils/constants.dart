class AppConstants {
  AppConstants._();

  static const String appName = 'H2Orbit';
  static const String appVersion = '1.1.0';

  // Hydration
  static const int defaultWaterTarget = 8; // glasses
  static const int minGlassTarget = 4;
  static const int maxGlassTarget = 16;
  static const int mlPerGlass = 250;

  /// How many days of history are loaded for streaks and analytics.
  static const int historyDays = 120;

  // Glass UI
  static const double glassOpacity = 0.15;
  static const double glassBlur = 10.0;
  static const double borderRadius = 20.0;

  /// OpenWeatherMap key, supplied at build time so it never lives in the repo:
  ///   flutter run --dart-define=OPENWEATHER_API_KEY=your_key
  /// Without it the weather features are simply hidden.
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
  );
}
