import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF0A1828);
  static const Color oceanBlue = Color(0xFF178582);
  static const Color deepCyan = Color(0xFF0E4C5C);
  static const Color lightCyan = Color(0xFF4DD0E1);
  static const Color waveBlue = Color(0xFF1565C0);

  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1828), Color(0xFF178582), Color(0xFF4DD0E1)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x40178582), Color(0x404DD0E1)],
  );
}

class AppConstants {
  static const double glassOpacity = 0.15;
  static const double glassBlur = 10.0;
  static const double borderRadius = 20.0;
  static const int mlPerGlass = 250;
}
