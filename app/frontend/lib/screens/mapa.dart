import 'package:eventvsmerida/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/eventos_guardados_service.dart';
import '../widgets/componentes_compartidos.dart';

class Mapa extends StatefulWidget {
  const Mapa({super.key});

  @override
  State<Mapa> createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  static const LatLng _merida = LatLng(38.9161, -6.3437);
  static const double _zoomInicial = 14.0;
  static const int _maxEventosMapa = 20;

  Map<String, List<Evento>> _eventosAgrupados = {};
  bool _cargando = true;
  String? _mensajeError;

  Usuario? _usuario;
  List<Evento> _eventosGuardados = [];

  GlobalKey keyPinLocalizacion = GlobalKey();

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _cargarUsuarioYGuardados();
    _cargarEventosParaMapa();
  }

  bool _targetEstaListo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return false;

    final renderObject = ctx.findRenderObject();
    return renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize;
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

  Future<void> _cargarUsuarioYGuardados() async {
    final (usuario, guardados) =
    await EventosGuardadosService.cargarUsuarioYEventosGuardados();

    if (!mounted) return;

    setState(() {
      _usuario = usuario;
      _eventosGuardados = guardados;
    });
  }

  Future<void> _cargarEventosParaMapa() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    final respuesta = await ApiService.obtenerEventos();

    if (!mounted) return;

    if (!respuesta.exito) {
      setState(() {
        _cargando = false;
        _mensajeError = respuesta.mensaje;
      });

      _mostrarMensaje(respuesta.mensaje);
      return;
    }

    final eventos = respuesta.datos ?? const <Evento>[];
    final eventosParaMapa = _obtenerEventosParaMapa(eventos);
    final agrupados = _agruparEventosPorCoordenadas(eventosParaMapa);

    setState(() {
      _eventosAgrupados = agrupados;
      _cargando = false;
      _mensajeError = null;
    });

    await _cargarTutorial();
  }

  Future<void> _cargarTutorial() async {
    if (await SharedPreferencesService.cargarTutorial()) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        _comprobarInicializacionTutorial();
      });
    }
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  bool _eventoTieneCoordenadas(Evento evento) {
    return evento.latitud != null && evento.longitud != null;
  }

  bool _eventoNoHaTerminado(Evento evento) {
    return evento.fechaFin.isAfter(DateTime.now());
  }

  List<Evento> _obtenerEventosParaMapa(List<Evento> eventos) {
    final eventosValidos = eventos.where((evento) {
      return _eventoTieneCoordenadas(evento) && _eventoNoHaTerminado(evento);
    }).toList();

    eventosValidos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));

    return eventosValidos.take(_maxEventosMapa).toList();
  }

  String _claveUbicacion(Evento evento) {
    return '${evento.latitud},${evento.longitud}';
  }

  Map<String, List<Evento>> _agruparEventosPorCoordenadas(
      List<Evento> eventos,
      ) {
    final agrupados = <String, List<Evento>>{};

    for (final evento in eventos) {
      final clave = _claveUbicacion(evento);
      agrupados.putIfAbsent(clave, () => []).add(evento);
    }

    return agrupados;
  }

  // ===========================================================================
  // MODALES
  // ===========================================================================

  void _abrirModalEvento(List<Evento> eventosEnLugar) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => ModalEvento(
        eventos: eventosEnLugar,
        usuario: _usuario,
        eventosGuardados: _eventosGuardados,
        onEventosGuardadosActualizados: (nuevaLista) {
          setState(() {
            _eventosGuardados = nuevaLista;
          });
        },
        mostrarBotonGuardado: true,
        mostrarFlechasDeslizamiento: true,
      ),
    );
  }

  // ===========================================================================
  // MENSAJES
  // ===========================================================================

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  List<Marker> _buildMarcadores() {
    final grupos = _eventosAgrupados.values.toList();

    return List.generate(grupos.length, (index) {
      final eventosEnLugar = grupos[index];
      final primerEvento = eventosEnLugar.first;
      final esPrimerPin = index == 0;

      return Marker(
        point: LatLng(primerEvento.latitud!, primerEvento.longitud!),
        width: 55,
        height: 65,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          key: esPrimerPin ? keyPinLocalizacion : null,
          onTap: () => _abrirModalEvento(eventosEnLugar),
          child: PinConFoto(
            imagePath: 'assets/images/logo-eventvs-merida.png',
            cantidadEventos: eventosEnLugar.length,
          ),
        ),
      );
    });
  }

  Widget _buildMapa() {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: _merida,
        initialZoom: _zoomInicial,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'es.nullpointers.eventvsmerida',
        ),
        MarkerLayer(
          markers: _buildMarcadores(),
        ),
      ],
    );
  }

  Widget _buildCargando() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Card(
          color: _cs.surface,
          surfaceTintColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 42,
                  color: _cs.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _mensajeError ?? 'No se pudieron cargar los eventos',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _cargarEventosParaMapa,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TUTORIAL
  // ===========================================================================

  void _comprobarInicializacionTutorial() {
    if (!mounted) return;
    if (Tutorial.numPantalla != 2) return;
    if (Tutorial.tutorialInicializado) return;
    if (_cargando) return;
    if (_eventosAgrupados.isEmpty) return;
    if (!_targetEstaListo(keyPinLocalizacion)) return;

    Tutorial.tutorialInicializado = true;
    _configurarTutorial();
  }

  void _configurarTutorial() {
    Tutorial.navPasoActivo.value = false;
    Tutorial.pasosTutorial.clear();
    cargarPasosTutorial();

    Tutorial.tutorial = Tutorial.crearTutorial(
      context: context,
      pasosTutorial: Tutorial.pasosTutorial,
      color: Theme.of(context).colorScheme.primary,
    );

    Tutorial.mostrarTutorial(context);
  }

  void cargarPasosTutorial() {
    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: keyPinLocalizacion,
        titulo: 'Localización',
        descripcion:
        'En estos pines puedes visualizar y ubicar los eventos en el mapa de Mérida. Si pulsas en uno de ellos, podrás ver nuevamente el detalle de este.',
        icon: Icons.event,
        siguiente: true,
        onNext: () => Tutorial.tutorial.next(),
      ),
    );

    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: Tutorial.keyNavCalendario,
        titulo: 'Calendario',
        descripcion: 'Ahora pasemos al calendario para ver sus funcionalidades.',
        icon: Icons.calendar_month,
        siguiente: true,
        onNext: () async {
          Tutorial.navPasoActivo.value = false;
          Tutorial.numPantalla = 3;
          Tutorial.tutorialInicializado = false;
          Tutorial.tutorial.finish();

          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          context.go('/calendario');
        },
        alineamientoTarjeta: ContentAlign.top,
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          _buildMapa(),
          if (_cargando) _buildCargando(),
          if (!_cargando && _mensajeError != null) _buildError(),
        ],
      ),
    );
  }
}

// ===========================================================================
// WIDGET DEL PIN
// ===========================================================================

class PinConFoto extends StatelessWidget {
  final String imagePath;
  final int cantidadEventos;

  const PinConFoto({
    super.key,
    required this.imagePath,
    required this.cantidadEventos,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 55,
      height: 65,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Icon(
            Icons.location_on,
            size: 65,
            color: cs.primary,
          ),
          Positioned(
            top: 8,
            right: 6,
            child: CircleAvatar(
              radius: 17,
              child: CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(imagePath),
              ),
            ),
          ),
          if (cantidadEventos > 1)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$cantidadEventos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}