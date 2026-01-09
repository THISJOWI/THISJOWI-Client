import 'package:flutter/material.dart';

class AppTheme {
  // Dark Mode Colors
  static const Color darkBackground = Color.fromRGBO(23, 23, 23, 1.0);
  static const Color darkText = Color.fromRGBO(229, 228, 226, 1.0);
  static const Color darkBottomNavBar = Color.fromRGBO(13, 13, 13, 1.0);
  static const Color darkCardBg = Color.fromRGBO(30, 30, 30, 1.0);

  // Light Mode Colors
  static const Color lightBackground = Color.fromRGBO(250, 250, 250, 1.0);
  static const Color lightText = Color.fromRGBO(25, 25, 25, 1.0);
  static const Color lightBottomNavBar = Color.fromRGBO(240, 240, 240, 1.0);
  static const Color lightCardBg = Color.fromRGBO(245, 245, 245, 1.0);

  // Accent Colors (same for both themes)
  static const Color primary = Color.fromRGBO(33, 150, 243, 1.0);
  static const Color accent = Color.fromRGBO(33, 150, 243, 1.0);
  static const Color success = Color.fromRGBO(76, 175, 80, 1.0);
  static const Color error = Color.fromRGBO(244, 67, 54, 1.0);
  static const Color warning = Color.fromRGBO(255, 152, 0, 1.0);

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primary,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkText.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: darkText.withOpacity(0.1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: darkText.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: darkText.withOpacity(0.3),
            width: 1,
          ),
        ),
        labelStyle: TextStyle(
          color: darkText.withOpacity(0.6),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: darkText,
        selectionColor: darkText.withOpacity(0.3),
        selectionHandleColor: darkText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkText,
          foregroundColor: darkBackground,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkText,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardColor: darkCardBg,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: darkText),
        bodyMedium: TextStyle(color: darkText),
        bodySmall: TextStyle(color: darkText.withOpacity(0.7)),
        titleLarge: TextStyle(
          color: darkText,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(color: darkText),
        titleSmall: TextStyle(color: darkText.withOpacity(0.6)),
      ), dialogTheme: DialogThemeData(backgroundColor: darkBackground),
    );
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primary,
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightText.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: lightText.withOpacity(0.1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: lightText.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: lightText.withOpacity(0.6),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightText,
          foregroundColor: lightBackground,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightText,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardColor: lightCardBg,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: lightText),
        bodyMedium: TextStyle(color: lightText),
        bodySmall: TextStyle(color: lightText.withOpacity(0.7)),
        titleLarge: TextStyle(
          color: lightText,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(color: lightText),
        titleSmall: TextStyle(color: lightText.withOpacity(0.6)),
      ), dialogTheme: DialogThemeData(backgroundColor: lightBackground),
    );
  }
}
