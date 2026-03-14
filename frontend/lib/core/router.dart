import 'package:eventvsmerida/screens/calendario.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/mapa.dart';
import '../screens/splash.dart';
import '../screens/login.dart';
import '../screens/registro.dart';
import '../screens/navegador.dart';
import '../screens/eventos.dart';
import '../screens/perfil.dart';
import '../screens/terminos.dart';
import '../screens/privacidad.dart';
import '../screens/cuenta.dart';
import '../screens/eventos_guardados.dart';

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
          path: '/calendario',
          builder: (context, state) => const Calendario(),
        ),
        GoRoute(
          path: '/mapa',
          builder: (context, state) => const Mapa(),
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
        GoRoute(
          path: '/terminos',
          builder: (context, state) => const Terminos(),
        ),
        GoRoute(
          path: '/privacidad',
          builder: (context, state) => const Privacidad(),
        ),
        GoRoute(
          path: '/cuenta',
          builder: (context, state) => const Cuenta(),
        ),
        GoRoute(
          path: '/eventos_guardados',
          builder: (context, state) => const EventosGuardados(),
        ),
      ],
    ),
  ],
);