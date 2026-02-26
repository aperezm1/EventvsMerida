import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/splash.dart';
import 'screens/login.dart';
import 'screens/registro.dart';
import 'screens/navegador.dart';
import 'screens/eventos.dart';
import 'screens/perfil.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const Splash(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return Navegador(child: child);
      },
      routes: [
        GoRoute(
          path: '/eventos',
          builder: (context, state) => const Eventos(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Login(),
        ),
        GoRoute(
          path: '/registro',
          builder: (context, state) => const Registro(),
        ),
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const Perfil(),
        ),
      ],
    ),
  ],
);