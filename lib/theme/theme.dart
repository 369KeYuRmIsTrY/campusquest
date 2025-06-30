// lib/theme/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBlue = Color(0xFF2C2966);
  static const Color veryDarkBlue = Color(0xFF131047);
  static const Color greyishBlue = Color(0xFF6C6C94);
  static const Color orange = Color(0xFFFFA051);
  static const Color lightBackground = Color(0xFFF4F4F7);

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: darkBlue,
    hintColor: orange, // Used for accents like floating action button
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: veryDarkBlue,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: orange,
      foregroundColor: Colors.white,
    ),
    // You might want to define cardColor if you have cards
    cardColor: Colors.white,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    hintColor: orange, // Used for accents like floating action button
    scaffoldBackgroundColor: veryDarkBlue,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: orange,
      foregroundColor: Colors.white,
    ),
    cardColor: greyishBlue.withOpacity(0.2), // Example dark card color
  );
}
