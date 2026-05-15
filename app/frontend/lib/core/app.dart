import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router/router.dart';
import 'theme/controlador_tema.dart';
import 'theme/tema.dart';

/// Clase principal de la aplicación, que configura el tema o el enrutamiento.
///
/// @author: Eva Retamar
/// @author: Adrián Pérez
/// @author: David Muñoz
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Eventvs Mérida',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          routerConfig: appRouter,
          supportedLocales: const [Locale('es', '')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}