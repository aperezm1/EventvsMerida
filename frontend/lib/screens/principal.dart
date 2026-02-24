import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Principal extends StatefulWidget {
  final Widget child;

  const Principal({super.key, required this.child});

  @override
  State<StatefulWidget> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  int _indiceActual = 0;

  int _calcularIndice(String localizacion) {
    switch (localizacion) {
      case '/inicio':
        return 0;
      case '/login':
        return 1;
    }
    return 0;
  }

  void _cambiarRuta(int indice) {
    switch (indice) {
      case 0:
        context.go('/inicio');
        break;
      case 1:
        context.go('/login');
        break;
    }
  }

  void _probarBoton() {
    SnackBar(content: Text("Botón funcionando"));
  }

  @override
  Widget build(BuildContext context) {
    final localizacion = GoRouterState.of(context).uri.toString();
    _indiceActual = _calcularIndice(localizacion);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: SizedBox(
          height: 190,
          // ajusta a la altura que mejor veas (30–48 suele ir bien)
          child: Image.asset(
            'assets/images/logo-eventvs-merida-no-bg.png',
            fit: BoxFit.contain, // asegura que no se recorte
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsetsGeometry.all(15),
            child: Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                  ),
                  onPressed: _probarBoton,
                  child: Icon(Icons.search, size: 25),
                ),
                SizedBox(width: 5),
                ElevatedButton(
                  onPressed: null,
                  child: Icon(Icons.filter_alt_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.red,
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.amberAccent,
        currentIndex: _indiceActual,
        iconSize: 30,
        onTap: _cambiarRuta,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month, color: Colors.black),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
