import 'package:flutter/material.dart';
import 'theme/controlador_tema.dart';
import 'theme/tema_claro.dart';
import 'theme/tema_oscuro.dart';
import 'router.dart';

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
          routerConfig: router,
        );
      },
    );
  }
}