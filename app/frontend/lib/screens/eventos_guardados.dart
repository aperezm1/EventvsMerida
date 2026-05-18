import 'package:eventvsmerida/utils/fecha_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';
import '../widgets/componentes_compartidos.dart';

/// Pantalla que muestra los eventos guardados por el usuario.
/// Permite ver detalles de cada evento y eliminar eventos guardados.
///
/// @author: Eva Retamar
/// @author: Adrián Pérez
/// @author: David Muñoz
class EventosGuardados extends StatefulWidget {
  const EventosGuardados({super.key});

  @override
  State<EventosGuardados> createState() => _EventosGuardadosState();
}

class _EventosGuardadosState extends State<EventosGuardados> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  Usuario? _usuario;
  List<Evento> _eventos = [];
  bool _cargando = true;
  FechaUtils fu = FechaUtils();

  final ScrollController _eventosScrollController = ScrollController();
  final ValueNotifier<int> _actualizadorScrollbar = ValueNotifier<int>(0);

  static const double _paddingVerticalLista = 16;
  static const double _paddingVerticalTarjeta = 10;
  static const double _margenVerticalScrollbar =
      _paddingVerticalLista + _paddingVerticalTarjeta;

  static const double _grosorScrollbar = 6;
  static const double _radioScrollbar = 20;
  static const double _margenDerechoScrollbar = 4;
  static const double _altoMinimoScrollbar = 48;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _eventosScrollController.dispose();
    _actualizadorScrollbar.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

  Future<void> _cargarDatos() async {
    final usuario = await SharedPreferencesService.cargarUsuario();
    final respuesta = await ApiService.obtenerEventosGuardados(usuario!.email);

    if (!mounted) return;

    setState(() {
      _usuario = usuario;
      _eventos = respuesta.exito ? (respuesta.datos ?? []) : [];
      _cargando = false;
    });

    if (!respuesta.exito) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: respuesta.mensaje,
        icon: Icons.event_busy,
        color: _cs.error,
      );
    }
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  bool _esMismoEvento(Evento a, Evento b) {
    return a.titulo == b.titulo &&
        a.fechaInicio == b.fechaInicio &&
        a.fechaFin == b.fechaFin;
  }

  String _textoFechaEvento(Evento evento) {
    if (fu.esMismoDia(evento.fechaInicio, evento.fechaFin)) {
      return 'Fecha: ${fu.formatearFecha(evento.fechaInicio)} · ${fu.formatearHora(evento.fechaInicio)} - ${fu.formatearHora(evento.fechaFin)}';
    }

    return 'Desde: ${fu.formatearFecha(evento.fechaInicio)} ${fu.formatearHora(evento.fechaInicio)}\n'
        'Hasta: ${fu.formatearFecha(evento.fechaFin)} ${fu.formatearHora(evento.fechaFin)}';
  }

  Future<void> _borrarEvento(Evento evento) async {
    final email = _usuario?.email;
    if (email == null) return;

    final respuesta = await ApiService.eliminarEventoUsuario(
      email,
      evento.titulo,
      evento.fechaInicio,
      evento.fechaFin,
    );

    if (respuesta.exito) {
      setState(() {
        _eventos.removeWhere((e) => _esMismoEvento(e, evento));
      });
    }

    if (!mounted) return;

    Mensaje.mostrarSnackBar(
      context: context,
      mensaje: respuesta.mensaje,
      icon: Icons.event_busy,
      color: _cs.error,
    );
  }

  // ===========================================================================
  // MODALES
  // ===========================================================================

  void _abrirModalEvento(Evento evento) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => ModalEvento(
        eventos: [evento],
        usuario: _usuario,
        eventosGuardados: _eventos,
        onEventosGuardadosActualizados: (nuevaLista) {
          setState(() {
            _eventos = nuevaLista;
          });
        },
        mostrarBotonGuardado: false,
      ),
    );
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _buildHeader() {
    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
        color: _cs.primary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: _cs.surface),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ),
                Center(
                  child: Text(
                    'Eventos guardados',
                    style: TextStyle(
                      color: _cs.surface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            'No tienes eventos guardados',
            style: TextStyle(color: _cs.onSurface, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _imagenEvento(String foto) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        bottomLeft: Radius.circular(18),
      ),
      child: Image.network(
        foto,
        width: 100,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 100,
          height: 110,
          color: _cs.secondary.withAlpha(51),
          child: Icon(Icons.image, color: _cs.primary),
        ),
      ),
    );
  }

  Widget _buildListaEventosGuardados() {
    final mostrarBarraScroll = _eventos.length >= 4;

    final lista = NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _actualizadorScrollbar.value++;
        return false;
      },
      child: ListView.builder(
        controller: _eventosScrollController,
        padding: const EdgeInsets.only(
          top: _paddingVerticalLista,
          bottom: _paddingVerticalLista,
        ),
        itemCount: _eventos.length,
        itemBuilder: (context, index) => _tarjetaEvento(_eventos[index]),
      ),
    );

    if (!mostrarBarraScroll) {
      return lista;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            lista,
            Positioned(
              top: 0,
              right: _margenDerechoScrollbar,
              bottom: 0,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _eventosScrollController,
                    _actualizadorScrollbar,
                  ]),
                  builder: (context, child) {
                    if (!_eventosScrollController.hasClients) {
                      return const SizedBox.shrink();
                    }

                    final posicion = _eventosScrollController.position;

                    if (!posicion.hasContentDimensions) {
                      return const SizedBox.shrink();
                    }

                    final maxScroll = posicion.maxScrollExtent;

                    if (maxScroll <= 0) {
                      return const SizedBox.shrink();
                    }

                    final altoDisponible = constraints.maxHeight;
                    final altoCarril =
                        altoDisponible - (_margenVerticalScrollbar * 2);

                    if (altoCarril <= 0) {
                      return const SizedBox.shrink();
                    }

                    final altoContenido = posicion.extentInside + maxScroll;

                    final altoScrollbar =
                    (posicion.extentInside / altoContenido * altoCarril)
                        .clamp(_altoMinimoScrollbar, altoCarril)
                        .toDouble();

                    final porcentajeScroll =
                    (_eventosScrollController.offset / maxScroll)
                        .clamp(0.0, 1.0)
                        .toDouble();

                    final desplazamientoScrollbar =
                        (altoCarril - altoScrollbar) * porcentajeScroll;

                    return SizedBox(
                      width: _grosorScrollbar,
                      height: altoDisponible,
                      child: Stack(
                        children: [
                          Positioned(
                            top: _margenVerticalScrollbar +
                                desplazamientoScrollbar,
                            right: 0,
                            child: Container(
                              width: _grosorScrollbar,
                              height: altoScrollbar,
                              decoration: BoxDecoration(
                                color: _cs.primary,
                                borderRadius:
                                BorderRadius.circular(_radioScrollbar),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tarjetaEvento(Evento evento) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: _paddingVerticalTarjeta,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _abrirModalEvento(evento),
          child: Container(
            decoration: BoxDecoration(
              color: _cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cs.primary, width: 1),
              boxShadow: [
                BoxShadow(
                  color: _cs.onPrimary.withAlpha(64),
                  blurRadius: 5,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _imagenEvento(evento.foto),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evento.titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _cs.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          evento.localizacion,
                          style: TextStyle(
                            color: _cs.onSurface.withAlpha(178),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _textoFechaEvento(evento),
                          style: TextStyle(
                            fontSize: 13,
                            color: _cs.onSurface,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: _cs.error),
                  onPressed: () => _borrarEvento(evento),
                  tooltip: 'Eliminar evento',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cs.surface,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _eventos.isEmpty
                ? _contenidoVacio()
                : _buildListaEventosGuardados(),
          ),
        ],
      ),
    );
  }
}