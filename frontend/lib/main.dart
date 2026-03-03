import 'package:flutter/material.dart';
import 'router.dart';
import 'controlador_tema.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return MaterialApp.router(
          title: 'Eventvs Mérida',
          theme: ThemeData(
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
          ),
          darkTheme: ThemeData(
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
          ),
          themeMode: mode,
          routerConfig: router,
        );
      },
    );
  }
}