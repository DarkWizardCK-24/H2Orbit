import 'package:flutter/material.dart';

/// Colours, gradients and the dark "ocean" Material theme.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Poppins';

  static const Color darkBackground = Color(0xFF0A1828);
  static const Color oceanBlue = Color(0xFF178582);
  static const Color deepCyan = Color(0xFF0E4C5C);
  static const Color lightCyan = Color(0xFF4DD0E1);
  static const Color waveBlue = Color(0xFF1565C0);

  static const Color success = Color(0xFF69DB8C);
  static const Color warning = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color streak = Color(0xFFFF9F43);

  /// Deep navy to teal. It stays dark enough everywhere that the cyan accent
  /// colour keeps good contrast on top of it.
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1828), Color(0xFF0E4C5C), Color(0xFF178582)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x40178582), Color(0x404DD0E1)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightCyan, oceanBlue],
  );

  static ThemeData dark() {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    final scheme =
        ColorScheme.fromSeed(
          seedColor: lightCyan,
          brightness: Brightness.dark,
        ).copyWith(
          primary: lightCyan,
          secondary: oceanBlue,
          surface: deepCyan,
          error: danger,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: deepCyan,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
      ),
      // One glass-style input look for every form in the app.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        prefixIconColor: lightCyan,
        suffixIconColor: lightCyan,
        errorStyle: const TextStyle(color: danger),
        border: border(Colors.white.withValues(alpha: 0.25)),
        enabledBorder: border(Colors.white.withValues(alpha: 0.25)),
        focusedBorder: border(lightCyan, 2),
        errorBorder: border(danger),
        focusedErrorBorder: border(danger, 2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: deepCyan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 14,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: deepCyan,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: deepCyan,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? Colors.white : Colors.white70,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? lightCyan
              : Colors.white.withValues(alpha: 0.2),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: lightCyan,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.15),
        thickness: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: lightCyan,
        selectionHandleColor: lightCyan,
        selectionColor: lightCyan.withValues(alpha: 0.3),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightCyan,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lightCyan,
          foregroundColor: darkBackground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
