import 'package:flutter/material.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'screens/registro.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventvs Mérida',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF0074E8),           // Azul
          onPrimary: Colors.black,
          secondary: Color(0xFFACD2F8),         // Celeste claro
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
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFEE8D24),           // Naranja
          onPrimary: Colors.white,
          secondary: Color(0xFFFFC483),         // Naranja claro
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
      themeMode: ThemeMode.system,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const Splash(),
        '/registro': (context) => const Registro(),
        '/login': (context) => const Login(),
      },
    );
  }
}