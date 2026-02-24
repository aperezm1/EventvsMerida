import 'package:eventvsmerida/screens/principal.dart';
import 'package:flutter/material.dart';
import 'inicio.dart';
import 'registro.dart';
import 'login.dart';
import 'package:go_router/go_router.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      context.go('/inicio');
      // Navigator.pushReplacement(
      //   context,
      //   //MaterialPageRoute(builder: (context) => const Login()),
      //   //MaterialPageRoute(builder: (context) => const Registro()),
      //   //MaterialPageRoute(builder: (context) => const Inicio());
      // );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorFondo = Theme.of(context).colorScheme.surface;
    return Scaffold(
      backgroundColor: colorFondo,
      body: Center(
        child: Image.asset(
          'assets/images/logo-eventvs-merida-no-bg.png',
          width: 350,
        ),
      ),
    );
  }
}