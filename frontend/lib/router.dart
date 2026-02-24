import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/splash.dart';
import 'screens/login.dart';
import 'screens/registro.dart';
import 'screens/principal.dart';
import 'screens/inicio.dart';

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
        return Principal(child: child);
      },
      routes: [
        GoRoute(
          path: '/inicio',
          builder: (context, state) => const Inicio(), // o la pantalla que quieras
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Login(),
        ),
        GoRoute(
          path: '/registro',
          builder: (context, state) => const Registro(),
        ),
      ],
    ),
  ],
);