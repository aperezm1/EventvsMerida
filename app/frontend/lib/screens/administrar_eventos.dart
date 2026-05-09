import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../services/api_service.dart';

class AdministrarEventos extends StatelessWidget {
  const AdministrarEventos({super.key});

  @override
  State<AdministrarEventos> createState() => _AdministrarEventosState();
}

class _AdministrarEventosState extends State<AdministrarEventos> {
  List<Evento> _eventos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    setState(() {
      _cargando = true;
    });

    final respuesta = await ApiService.obtenerEventos();

    if (!mounted) return;

    setState(() {
      _eventos = respuesta.datos ?? [];
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: _cs.surface,
      appBar: AppBar(
        title: const Text('Administrar eventos'),
        backgroundColor: _cs.primary,
        foregroundColor: _cs.surface,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final creado = await context.push<bool>(
                        AppRoutes.formularioEvento,
                      );
                      if (creado == true) {
                        // Más adelante aquí recargaremos la lista de eventos
                      }                },
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir evento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.surface,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: Text(
                      'Aquí se mostrarán los eventos que puede gestionar el organizador.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurface),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}