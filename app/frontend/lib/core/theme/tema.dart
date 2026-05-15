import 'package:flutter/material.dart';

/// Clase que define el tema de la aplicación, incluyendo los colores
/// y estilos para la interfaz de usuario.
///
/// @author: Eva Retamar
/// @author: Adrián Pérez
/// @author: David Muñoz
ThemeData buildTheme({required ColorScheme colorScheme, required AppBarTheme appBarTheme}) {
  return ThemeData(
    colorScheme: colorScheme,
    appBarTheme: appBarTheme,
  );
}
/// Tema claro
final ThemeData lightTheme = buildTheme(
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0074E8),
    onPrimary: Colors.black,
    secondary: Color(0xFFACD2F8),
    onSecondary: Colors.black,
    error: Colors.red,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFACD2F8),
    foregroundColor: Colors.black,
  ),
);

/// Tema oscuro
final ThemeData darkTheme = buildTheme(
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