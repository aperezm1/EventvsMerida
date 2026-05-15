import 'dart:ui';

import 'package:eventvsmerida/utils/fecha_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';
import '../widgets/componentes_compartidos.dart';

/// Pantalla para que administradores y organizadores puedan gestionar los eventos.
///
/// @author: Eva Retamar
/// @author: Adrián Pérez
/// @author: David Muñoz
class AdministrarEventos extends StatefulWidget {
  const AdministrarEventos({super.key});

  @override
  State<AdministrarEventos> createState() => _AdministrarEventosState();
}

class _AdministrarEventosState extends State<AdministrarEventos> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  Usuario? _usuario;
  List<Evento> _eventos = [];
  bool _cargando = true;
  int _paginaActual = 0;
  bool _ultimaPagina = false;
  bool _cargandoMas = false;
  static const int _tamanoPagina = 15;
  FechaUtils fu = FechaUtils();
  final TextEditingController controllerBusqueda = TextEditingController();
  final ScrollController _listaScrollController = ScrollController();
  String textoBusqueda = '';
  List<Evento> eventosEncontrados = [];
  bool eventosBuscados = false;
  bool _cargandoBusqueda = false;
  String _criterioBusquedaActual = '';

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _listaScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _listaScrollController.dispose();
    controllerBusqueda.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _paginaActual = 0;
      _ultimaPagina = false;
      _eventos = [];
    });

    final usuario = await SharedPreferencesService.cargarUsuario();

    if (!mounted) return;

    if (usuario == null) {
      setState(() {
        _usuario = null;
        _eventos = [];
        _cargando = false;
      });

      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'No hay usuario logueado',
        icon: Icons.person,
        color: _cs.error,
      );
      return;
    }

    final rol = usuario.rol.trim().toLowerCase();

    if (rol == 'administrador') {
      final resultado = await ApiService.obtenerEventosPaginados(
        page: 0,
        size: _tamanoPagina,
        fechaFinDesde: null,
      );

      if (!mounted) return;

      if (resultado == null || resultado['error'] != null) {
        setState(() {
          _usuario = usuario;
          _eventos = [];
          _cargando = false;
        });

        Mensaje.mostrarSnackBar(
          context: context,
          mensaje: resultado?['error'] ?? 'No se pudieron cargar los eventos',
          icon: Icons.event_busy_outlined,
          color: _cs.error,
        );
        return;
      }

      setState(() {
        _usuario = usuario;
        _eventos = List<Evento>.from(resultado['items'] ?? []);
        _ultimaPagina = resultado['last'] == true;
        _paginaActual = 0;
        _cargando = false;
      });

      if (textoBusqueda.trim().isNotEmpty) {
        buscarEventos(textoBusqueda);
      }

      return;
    }

    if (rol == 'organizador') {
      final respuesta = await ApiService.obtenerEventosPorOrganizador(
        usuario.id,
      );

      if (!mounted) return;

      setState(() {
        _usuario = usuario;
        _eventos = respuesta.exito ? (respuesta.datos ?? []) : [];
        _cargando = false;
      });

      if (textoBusqueda.trim().isNotEmpty) {
        buscarEventos(textoBusqueda);
      }

      if (!respuesta.exito) {
        Mensaje.mostrarSnackBar(
          context: context,
          mensaje: respuesta.mensaje,
          icon: Icons.close,
          color: _cs.error,
        );
      }

      return;
    }

    setState(() {
      _usuario = usuario;
      _eventos = [];
      _cargando = false;
    });

    Mensaje.mostrarSnackBar(
      context: context,
      mensaje: 'No tienes permisos para administrar eventos',
      icon: Icons.event_busy_outlined,
      color: _cs.error,
    );
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  bool get _puedeAdministrar {
    final rol = _usuario?.rol.trim().toLowerCase();
    return rol == 'administrador' || rol == 'organizador';
  }

  void _onScroll() {
    if (!_listaScrollController.hasClients || _cargandoMas || _ultimaPagina) {
      return;
    }

    final posicion = _listaScrollController.position;
    if (posicion.pixels >= posicion.maxScrollExtent - 200) {
      _cargarMasEventos();
    }
  }

  Future<void> _cargarMasEventos() async {
    if (_cargandoMas || _ultimaPagina) return;

    final usuario = _usuario;
    if (usuario == null) return;

    final rol = usuario.rol.trim().toLowerCase();

    if (rol != 'administrador') return;

    setState(() {
      _cargandoMas = true;
    });

    final siguientePagina = _paginaActual + 1;

    final resultado = await ApiService.obtenerEventosPaginados(
      page: siguientePagina,
      size: _tamanoPagina,
      fechaFinDesde: null,
    );

    if (!mounted) return;

    if (resultado == null || resultado['error'] != null) {
      setState(() {
        _cargandoMas = false;
      });

      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: resultado?['error'] ?? 'No se pudieron cargar más eventos',
        icon: Icons.event_busy_outlined,
        color: _cs.error,
      );
      return;
    }

    final nuevosEventos = List<Evento>.from(resultado['items'] ?? []);

    setState(() {
      _eventos.addAll(nuevosEventos);
      _paginaActual = siguientePagina;
      _ultimaPagina = resultado['last'] == true;
      _cargandoMas = false;
    });
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

  Future<void> _eliminarEvento(Evento evento) async {
    final respuesta = await ApiService.eliminarEvento(evento.id);

    if (!mounted) return;

    Mensaje.mostrarSnackBar(
      context: context,
      mensaje: respuesta.mensaje,
      icon: Icons.delete,
      color: respuesta.exito ? Colors.green : _cs.error,
    );

    if (respuesta.exito) {
      setState(() {
        _eventos.removeWhere((e) => e.id == evento.id);
      });
    }
  }

  Future<void> buscarEventos(String texto) async {
    final criterio = texto.trim().toLowerCase();
    _criterioBusquedaActual = criterio;

    if (criterio.isEmpty) {
      if (mounted) {
        setState(() {
          eventosEncontrados = [];
          eventosBuscados = false;
        });
      }
      return;
    }

    if (_cargandoBusqueda) {
      return;
    }

    setState(() {
      _cargandoBusqueda = true;
    });

    try {
      await _cargarTodosEventos();

      if (!mounted) return;

      _filtrarEventos(_criterioBusquedaActual);
    } finally {
      if (mounted) {
        setState(() {
          _cargandoBusqueda = false;
        });
      }
    }
  }

  void _filtrarEventos(String criterio) {
    setState(() {
      eventosEncontrados = _eventos.where((evento) {
        return evento.titulo.toLowerCase().contains(criterio) ||
            evento.localizacion.toLowerCase().contains(criterio) ||
            evento.nombreCategoria.toLowerCase().contains(criterio);
      }).toList();
      eventosBuscados = true;
    });
  }

  Future<void> _cargarTodosEventos() async {
    final usuario = _usuario;
    if (usuario == null) return;

    final rol = usuario.rol.trim().toLowerCase();
    if (rol != 'administrador') return;

    while (!_ultimaPagina && mounted) {
      await _cargarMasEventos();
    }
  }

  // ===========================================================================
  // MODALES
  // ===========================================================================

  Future<void> _modalConfirmarEliminar(Evento evento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(dialogContext, rootNavigator: true).pop(false);
                },
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withValues(alpha: 0.08)),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: cs.onSurface.withValues(alpha: 0.22),
                        blurRadius: 16,
                        spreadRadius: 1.5,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.delete,
                                    color: cs.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Eliminar evento',
                                              style: tt.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            icon: Icon(
                                              Icons.close,
                                              color: cs.onSurface,
                                            ),
                                            onPressed: () {
                                              Navigator.of(
                                                dialogContext,
                                                rootNavigator: true,
                                              ).pop(false);
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '¿Seguro que quieres eliminar "${evento.titulo}"?',
                                        style: tt.bodyMedium?.copyWith(
                                          color: cs.onSurface,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(
                                        dialogContext,
                                        rootNavigator: true,
                                      ).pop(false);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: cs.primary,
                                      side: BorderSide(color: cs.primary),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(
                                        dialogContext,
                                        rootNavigator: true,
                                      ).pop(true);
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: cs.surface,
                                    ),
                                    label: Text(
                                      'Eliminar',
                                      style: TextStyle(color: cs.surface),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: cs.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await _eliminarEvento(evento);
    }
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

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

  Widget _contenidoVacio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 64, color: _cs.primary),
          const SizedBox(height: 16),
          Text(
            'Aún no hay eventos creados.\n¡Añade el primero!',
            style: TextStyle(color: _cs.onSurface, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBuscador({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 16, right: 16, bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          focusColor: _cs.primary,
          suffixIcon: textoBusqueda.isEmpty
              ? const Icon(Icons.search_rounded)
              : IconButton(
                  icon: Icon(Icons.close_rounded, color: _cs.primary),
                  onPressed: () {
                    controller.clear();
                    textoBusqueda = '';
                    buscarEventos('');
                  },
                ),
          suffixIconColor: _cs.primary,
          label: Text('Buscar'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _cs.primary, width: 2),
          ),
        ),
        onChanged: (String valor) {
          textoBusqueda = valor;
          buscarEventos(valor);
        },
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
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/images/icono.gif',
                image: evento.foto,
                width: 90,
                height: 110,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                placeholderFit: BoxFit.cover,
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
                    fu.formatearFechaHora(evento.fechaInicio),
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
                        onPressed: () => _modalConfirmarEliminar(evento),
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
          Expanded(child: _contenidoVacio()),
        ],
      );
    }

    return Column(
      children: [
        _buildBotonAnadir(),
        _buildBuscador(label: 'Buscar', controller: controllerBusqueda),
        Expanded(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _cargarDatos,
                child: ListView.builder(
                  controller: _listaScrollController,
                  itemCount: eventosBuscados
                      ? eventosEncontrados.length + 1
                      : _eventos.length + 1,
                  itemBuilder: (context, index) {
                    final lista = eventosBuscados ? eventosEncontrados : _eventos;
                    if (index < lista.length) {
                      return _buildEventoCard(lista[index]);
                    }
                    if (eventosBuscados && lista.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 42,
                                  color: _cs.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No se han encontrado eventos para "$textoBusqueda"',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    final rol = _usuario?.rol.trim().toLowerCase();
                    if (rol != 'administrador') {
                      return const SizedBox(height: 16);
                    }
                    if (_cargandoMas || _cargandoBusqueda) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox(height: 16);
                  },
                ),
              ),
              if (_cargandoBusqueda)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: _cs.surface.withValues(alpha: 0.65),
                      child: Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(color: _cs.primary),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

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
