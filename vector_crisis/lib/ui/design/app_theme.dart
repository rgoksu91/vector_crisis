import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF070A16);
  static const surface = Color(0xFF12182B);
  static const surfaceLight = Color(0xFF1B2440);
  static const primary = Color(0xFF7C8CFF);
  static const secondary = Color(0xFF41D9C2);
  static const danger = Color(0xFFFF647C);
  static const gold = Color(0xFFFFC857);
}

ThemeData buildAppTheme() => ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    surface: AppColors.surface,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.w900,
      letterSpacing: -2,
      height: 0.95,
    ),
    headlineMedium: TextStyle(fontWeight: FontWeight.w900),
    titleLarge: TextStyle(fontWeight: FontWeight.w800),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(58),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
    ),
  ),
);
