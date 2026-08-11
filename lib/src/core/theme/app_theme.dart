import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bandana app theme configuration – Material 3 with custom color scheme.
class AppTheme {
  AppTheme._();

  // ── Color Tokens ──
  static const Color _seedColor = Color(0xFF00897B); // Teal 600
  static const Color _accelXColor = Color(0xFFEF5350); // Red
  static const Color _accelYColor = Color(0xFF66BB6A); // Green
  static const Color _accelZColor = Color(0xFF42A5F5); // Blue
  static const Color _gyroXColor = Color(0xFFFF7043); // Deep Orange
  static const Color _gyroYColor = Color(0xFFAB47BC); // Purple
  static const Color _gyroZColor = Color(0xFFFFA726); // Orange

  /// Chart line colors indexed by axis [ax, ay, az, gx, gy, gz].
  static const List<Color> axisColors = [
    _accelXColor,
    _accelYColor,
    _accelZColor,
    _gyroXColor,
    _gyroYColor,
    _gyroZColor,
  ];

  static const List<String> axisLabels = [
    'aX', 'aY', 'aZ', 'gX', 'gY', 'gZ',
  ];

  // ── Spacing Tokens ──
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  // ── Text Theme ──
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base);
  }

  // ── Light Theme ──
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );
    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
    );
  }

  // ── Dark Theme ──
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );
    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
    );
  }
}
