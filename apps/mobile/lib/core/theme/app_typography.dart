import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  );
}
