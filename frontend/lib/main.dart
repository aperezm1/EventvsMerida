import 'package:flutter/material.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/registro',
      routes: {
        '/registro': (context) => Registro(),
        '/login': (context) => Login(),
      },
    );
  }
}