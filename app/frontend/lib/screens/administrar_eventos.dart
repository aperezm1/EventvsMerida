import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/router/app_routes.dart';
import '../models/api_response.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';

class AdministrarEventos extends StatefulWidget {
  const AdministrarEventos({super.key});

  @override
  State<AdministrarEventos> createState() => _AdministrarEventosState();
}

class _AdministrarEventosState extends State<AdministrarEventos> {
  Usuario? _usuario;
  List<Evento> _eventos = [];
  bool _cargando = true;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
    });

    final usuario = await SharedPreferencesService.cargarUsuario();

    if (!mounted) return;

    if (usuario == null) {
      setState(() {
        _usuario = null;
        _eventos = [];
        _cargando = false;
      });
      _mostrarMensaje('No hay usuario logueado');
      return;
    }

    final ApiResponse<List<Evento>> respuesta;
    final rol = usuario.rol.trim().toLowerCase();

    if (rol == 'administrador') {
      respuesta = await ApiService.obtenerEventos();
    } else if (rol == 'organizador') {
      respuesta = await ApiService.obtenerEventosPorOrganizador(usuario.id);
    } else {
      setState(() {
        _usuario = usuario;
        _eventos = [];
        _cargando = false;
      });
      _mostrarMensaje('No tienes permisos para administrar eventos');
      return;
    }

    if (!mounted) return;

    setState(() {
      _usuario = usuario;
      _eventos = respuesta.exito ? (respuesta.datos ?? []) : [];
      _cargando = false;
    });

    if (!respuesta.exito) {
      _mostrarMensaje(respuesta.mensaje);
    }
  }

  bool get _puedeAdministrar {
    final rol = _usuario?.rol.trim().toLowerCase();
    return rol == 'administrador' || rol == 'organizador';
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  Future<void> _abrirFormularioCrear() async {
    final creado = await context.push<bool>(AppRoutes.formularioEvento);

    if (creado == true) {
      _cargarDatos();
    }
  }

  Future<void> _abrirFormularioEditar(Evento evento) async {
    final actualizado = await context.push<bool>(
      AppRoutes.formularioEvento,
      extra: evento,
    );

    if (actualizado == true) {
      _cargarDatos();
    }
  }

  Future<void> _confirmarEliminar(Evento evento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar evento'),
          content: Text('¿Seguro que quieres eliminar "${evento.titulo}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await _eliminarEvento(evento);
    }
  }

  Future<void> _eliminarEvento(Evento evento) async {
    final respuesta = await ApiService.eliminarEvento(evento.id);

    if (!mounted) return;

    _mostrarMensaje(respuesta.mensaje);

    if (respuesta.exito) {
      setState(() {
        _eventos.removeWhere((e) => e.id == evento.id);
      });
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Widget _buildBotonAnadir() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _abrirFormularioCrear,
          icon: const Icon(Icons.add),
          label: const Text('Añadir evento'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _cs.primary,
            foregroundColor: _cs.surface,
          ),
        ),
      ),
    );
  }

  Widget _buildEventoCard(Evento evento) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _cs.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                evento.foto,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 90,
                    height: 90,
                    color: _cs.secondary.withValues(alpha: 0.3),
                    child: Icon(Icons.image_not_supported, color: _cs.primary),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evento.localizacion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatearFecha(evento.fechaInicio),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _cs.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => _abrirFormularioEditar(evento),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmarEliminar(evento),
                        icon: Icon(Icons.delete, color: _cs.error),
                        label: Text(
                          'Eliminar',
                          style: TextStyle(color: _cs.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_puedeAdministrar) {
      return const Center(
        child: Text('No tienes permisos para administrar eventos'),
      );
    }

    if (_eventos.isEmpty) {
      return Column(
        children: [
          _buildBotonAnadir(),
          const Expanded(
            child: Center(
              child: Text('No hay eventos disponibles'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildBotonAnadir(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarDatos,
            child: ListView.builder(
              itemCount: _eventos.length,
              itemBuilder: (context, index) {
                return _buildEventoCard(_eventos[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cs.surface,
      appBar: AppBar(
        title: const Text('Administrar eventos'),
        backgroundColor: _cs.primary,
        foregroundColor: _cs.surface,
        centerTitle: true,
      ),
      body: _buildContenido(),
    );
  }
}