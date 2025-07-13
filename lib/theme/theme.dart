// lib/theme/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBlue = Color(0xFF2C2966);
  static const Color veryDarkBlue = Color(0xFF131047);
  static const Color greyishBlue = Color(0xFF6C6C94);
  static const Color orange = Color(0xFFFFA051);
  static const Color lightBackground = Color.fromARGB(255, 254, 254, 254);
  static const Color sapphireDark = Color(0xFF0A0F3C); // #0A0F3C
  static const Color sapphire = Color(0xFF2C5DA9); // #2C5DA9
  static const Color sapphireLight = Color(0xFFC8DAF9); // #C8DAF9
  static const Color shadowedGreen = Color(0xFF1C2529); // #1C2529
  static const Color mintGreen = Color(0xFFA1D1B1); // #A1D1B1
  static const Color velvetTealDark = Color(0xFF1B4242); // #1B4242
  static const Color velvetTeal = Color(0xFF4FBDBA); // #4FBDBA
  static const Color velvetTealLight = Color(0xFFCDEED6); // #CDEED6
  static const Color yachtClubLight = Color(0xFFF2F0EF); // #F2F0EF
  static const Color yachtClubGrey = Color(0xFFBBBD8C); // #BBBD8C
  static const Color yachtClubBlue = Color(0xFF245F73); // #245F73
  static const Color yachtClubBrown = Color(0xFF733E24); // #733E24

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: sapphire,
    hintColor: orange, // Used for accents like floating action button
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: yachtClubBlue,
      foregroundColor: yachtClubLight,
      iconTheme: IconThemeData(color: yachtClubLight),
      titleTextStyle: TextStyle(
        color: yachtClubLight,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: yachtClubBlue,
        foregroundColor: yachtClubLight,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: yachtClubBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: yachtClubBlue,
        side: const BorderSide(color: yachtClubBlue),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: orange,
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.white,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: sapphireLight,
    hintColor: orange, // Used for accents like floating action button
    scaffoldBackgroundColor: sapphireDark,
    appBarTheme: AppBarTheme(
      backgroundColor: yachtClubBlue,
      foregroundColor: yachtClubLight,
      iconTheme: IconThemeData(color: yachtClubLight),
      titleTextStyle: TextStyle(
        color: yachtClubLight,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: yachtClubBlue,
        foregroundColor: yachtClubLight,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: yachtClubBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: yachtClubBlue,
        side: const BorderSide(color: yachtClubBlue),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: orange,
      foregroundColor: Colors.white,
    ),
    cardColor: greyishBlue.withOpacity(0.2), // Example dark card color
  );
}
