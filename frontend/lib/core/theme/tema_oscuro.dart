import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFEE8D24),
    onPrimary: Colors.white,
    secondary: Color(0xFFFFC483),
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.black,
    surface: Colors.black,
    onSurface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEE8D24),
    foregroundColor: Colors.black,
  ),
);