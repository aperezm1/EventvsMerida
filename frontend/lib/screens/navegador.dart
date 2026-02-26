import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Navegador extends StatefulWidget {
  final Widget child;

  const Navegador({super.key, required this.child});

  @override
  State<StatefulWidget> createState() => _NavegadorState();
}

class _NavegadorState extends State<Navegador> {
  int _indiceActual = 0;

  int _calcularIndice(String localizacion) {
    switch (localizacion) {
      case '/eventos':
        return 0;
      case '/mapa':
        return 1;
      case '/calendario':
        return 2;
      case '/perfil':
        return 3;
    }
    return 0;
  }

  void _cambiarRuta(int indice) {
    switch (indice) {
      case 0:
        context.go('/eventos');
        break;
      case 1:
        //context.go('/mapa');
        break;
      case 2:
        //context.go('/calendario');
        break;
      case 3:
        context.go('/perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizacion = GoRouterState.of(context).uri.toString();
    _indiceActual = _calcularIndice(localizacion);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.primary,
        unselectedItemColor: colorScheme.surface.withValues(alpha: 0.5),
        selectedItemColor: colorScheme.surface,
        currentIndex: _indiceActual,
        iconSize: 30,
        onTap: _cambiarRuta,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendario',),
          BottomNavigationBarItem(icon: Icon(Icons.person_2_rounded), label: 'Perfil',),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}