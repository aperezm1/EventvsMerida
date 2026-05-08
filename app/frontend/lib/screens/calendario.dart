import 'package:eventvsmerida/core/router/app_routes.dart';
import 'package:eventvsmerida/services/shared_preferences_service.dart';
import 'package:eventvsmerida/utils/fecha_utils.dart';
import 'package:eventvsmerida/widgets/componentes_compartidos.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/eventos_guardados_service.dart';

class Calendario extends StatefulWidget {
  const Calendario({super.key});

  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  late final DateTime _primerMesPermitido;
  late final DateTime _ultimoMesPermitido;
  late final List<int> _years;

  late DateTime _focusedDay;
  DateTime? _selectedDay;

  bool _cargandoEventos = true;
  String? _mensajeError;
  Map<DateTime, List<Evento>> _eventosMap = {};

  Usuario? _usuario;
  List<Evento> _eventosGuardados = [];

  final ScrollController _eventosScrollController = ScrollController();

  static const List<String> _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  ColorScheme get _cs => Theme.of(context).colorScheme;

  GlobalKey keyCalendario = GlobalKey();
  GlobalKey keyListadoEventos = GlobalKey();

  FechaUtils fu = FechaUtils();

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    final ahora = DateTime.now();

    _primerMesPermitido = DateTime(ahora.year, ahora.month, 1);
    _ultimoMesPermitido = DateTime(2030, 12, 1);

    _focusedDay = DateTime(ahora.year, ahora.month, ahora.day);
    _selectedDay = DateTime(ahora.year, ahora.month, ahora.day);

    _years = List.generate(
      _ultimoMesPermitido.year - _primerMesPermitido.year + 1,
          (index) => _primerMesPermitido.year + index,
    );

    _cargarUsuarioYGuardados();
    _cargarEventos();
  }

  @override
  void dispose() {
    _eventosScrollController.dispose();
    super.dispose();
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

  Future<void> _cargarEventos() async {
    setState(() {
      _cargandoEventos = true;
      _mensajeError = null;
    });

    final respuesta = await ApiService.obtenerEventos();

    if (!mounted) return;

    if (!respuesta.exito) {
      setState(() {
        _cargandoEventos = false;
        _mensajeError = respuesta.mensaje;
      });

      Mensaje.mostrarSnackBar(context: context, mensaje: respuesta.mensaje, icon: Icons.wifi_off, color: Colors.red);
      return;
    }

    final eventos = respuesta.datos ?? const <Evento>[];

    setState(() {
      _eventosMap = _crearMapaPorDia(eventos);
      _cargandoEventos = false;
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

  Map<DateTime, List<Evento>> _crearMapaPorDia(List<Evento> eventos) {
    final mapa = <DateTime, List<Evento>>{};

    for (final evento in eventos) {
      final inicio = fu.normalizarFecha(evento.fechaInicio);
      final fin = fu.normalizarFecha(evento.fechaFin);
      final totalDias = fin.difference(inicio).inDays;

      for (var i = 0; i <= totalDias; i++) {
        final dia = fu.normalizarFecha(inicio.add(Duration(days: i)));
        mapa.putIfAbsent(dia, () => []);
        mapa[dia]!.add(evento);
      }
    }

    return mapa;
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  bool _esAntesDelPrimerMes(DateTime fecha) {
    final mes = DateTime(fecha.year, fecha.month, 1);
    return mes.isBefore(_primerMesPermitido);
  }

  bool _esDespuesDelUltimoMes(DateTime fecha) {
    final mes = DateTime(fecha.year, fecha.month, 1);
    return mes.isAfter(_ultimoMesPermitido);
  }

  bool _esEventoDeUnSoloDia(Evento evento) {
    return fu.esMismoDia(evento.fechaInicio, evento.fechaFin);
  }

  int _prioridadEvento(Evento evento, DateTime diaSeleccionado) {
    final finalizaHoy = fu.esMismoDia(evento.fechaFin, diaSeleccionado);
    final iniciaHoy = fu.esMismoDia(evento.fechaInicio, diaSeleccionado);

    if (finalizaHoy) return 0;
    if (iniciaHoy) return 1;
    return 2;
  }

  int _horaReferencia(Evento evento, DateTime diaSeleccionado) {
    final finalizaHoy = fu.esMismoDia(evento.fechaFin, diaSeleccionado);

    if (finalizaHoy) {
      return fu.minutosDelDia(evento.fechaFin);
    }

    return fu.minutosDelDia(evento.fechaInicio);
  }

  int _compararEventos(Evento a, Evento b, DateTime fecha) {
    final prioridadA = _prioridadEvento(a, fecha);
    final prioridadB = _prioridadEvento(b, fecha);

    if (prioridadA != prioridadB) {
      return prioridadA.compareTo(prioridadB);
    }

    final horaA = _horaReferencia(a, fecha);
    final horaB = _horaReferencia(b, fecha);

    if (horaA != horaB) {
      return horaA.compareTo(horaB);
    }

    return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
  }

  List<Evento> _eventosDelDiaSeleccionado() {
    final fechaSeleccionada = _selectedDay ?? _focusedDay;
    final fechaNormalizada = fu.normalizarFecha(fechaSeleccionada);
    final hoy = fu.normalizarFecha(DateTime.now());

    final esMesVisible =
        fechaNormalizada.month == _focusedDay.month &&
            fechaNormalizada.year == _focusedDay.year;

    if (!esMesVisible || fechaNormalizada.isBefore(hoy)) {
      return [];
    }

    final lista = List<Evento>.from(_eventosMap[fechaNormalizada] ?? []);

    lista.sort((a, b) => _compararEventos(a, b, fechaNormalizada));

    return lista;
  }

  String _textoEtiquetaTiempo(Evento evento, DateTime diaSeleccionado) {
    final iniciaHoy = fu.esMismoDia(evento.fechaInicio, diaSeleccionado);
    final finalizaHoy = fu.esMismoDia(evento.fechaFin, diaSeleccionado);

    final inicioHora = fu.formatearHora(evento.fechaInicio);
    final finHora = fu.formatearHora(evento.fechaFin);

    final inicioCero = fu.esHoraCero(evento.fechaInicio);
    final finCero = fu.esHoraCero(evento.fechaFin);

    if (_esEventoDeUnSoloDia(evento)) {
      if (inicioCero && finCero) return 'Todo el día';
      if (inicioHora == finHora) return inicioHora;
      if (inicioCero) return finHora;
      if (finCero) return inicioHora;
      return '$inicioHora - $finHora';
    }

    if (finalizaHoy) {
      if (finCero) return 'Finaliza';
      return 'Finaliza $finHora';
    }

    if (iniciaHoy) {
      if (inicioCero) return 'Inicia';
      return 'Inicia $inicioHora';
    }

    return 'En curso';
  }

  String _textoFechaCard(Evento evento) {
    final inicio = fu.formatearFecha(evento.fechaInicio);
    final fin = fu.formatearFecha(evento.fechaFin);

    if (_esEventoDeUnSoloDia(evento)) {
      return 'Fecha: $inicio';
    }

    return 'Fecha: $inicio - $fin';
  }

  List<DropdownMenuItem<int>> _buildMonthItems() {
    var mesInicio = 1;
    var mesFin = 12;

    if (_focusedDay.year == _primerMesPermitido.year) {
      mesInicio = _primerMesPermitido.month;
    }

    if (_focusedDay.year == _ultimoMesPermitido.year) {
      mesFin = _ultimoMesPermitido.month;
    }

    return List.generate(mesFin - mesInicio + 1, (index) {
      final mes = mesInicio + index;
      return DropdownMenuItem<int>(
        value: mes,
        child: Text(_months[mes - 1]),
      );
    });
  }

  void _actualizarFechaVisible(DateTime nuevaFecha) {
    final hoy = fu.normalizarFecha(DateTime.now());
    final nuevoMes = DateTime(nuevaFecha.year, nuevaFecha.month, 1);

    setState(() {
      _focusedDay = nuevaFecha;

      if (nuevaFecha.year == hoy.year && nuevoMes.month == hoy.month) {
        _selectedDay = hoy;
      } else {
        _selectedDay = nuevoMes;
      }
    });
  }

  void _reiniciarScrollEventos() {
    if (_eventosScrollController.hasClients) {
      _eventosScrollController.jumpTo(0);
    }
  }

  void _navegarAFecha(DateTime nuevaFecha) {
    _actualizarFechaVisible(nuevaFecha);
    _reiniciarScrollEventos();
  }

  bool _puedeIrMesAnterior() {
    final mesAnterior = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    return !_esAntesDelPrimerMes(mesAnterior);
  }

  bool _puedeIrMesSiguiente() {
    final mesSiguiente = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    return !_esDespuesDelUltimoMes(mesSiguiente);
  }

  void _cambiarMes(int incremento) {
    final nuevaFecha = DateTime(
      _focusedDay.year,
      _focusedDay.month + incremento,
      1,
    );

    _navegarAFecha(nuevaFecha);
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
        eventosGuardados: _eventosGuardados,
        onEventosGuardadosActualizados: (nuevaLista) {
          setState(() {
            _eventosGuardados = nuevaLista;
          });
        },
        mostrarBotonGuardado: true,
      ),
    );
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cs.primary.withValues(alpha: 128)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(
            color: _cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBotonCambioMes({
    required IconData icono,
    required bool habilitado,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 34,
      height: 42,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        splashRadius: 22,
        icon: Icon(
          icono,
          size: 32,
          color: habilitado
              ? _cs.primary
              : _cs.onSurface.withValues(alpha: 0.22),
        ),
        onPressed: habilitado ? onPressed : null,
      ),
    );
  }

  Widget _buildSelectoresFecha() {
    final puedeIrAnterior = _puedeIrMesAnterior();
    final puedeIrSiguiente = _puedeIrMesSiguiente();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBotonCambioMes(
          icono: Icons.chevron_left_rounded,
          habilitado: puedeIrAnterior,
          onPressed: () => _cambiarMes(-1),
        ),
        const SizedBox(width: 4),
        _buildDropdown<int>(
          value: _focusedDay.month,
          items: _buildMonthItems(),
          onChanged: (val) {
            if (val == null) return;
            _navegarAFecha(DateTime(_focusedDay.year, val, 1));
          },
        ),
        const SizedBox(width: 12),
        _buildDropdown<int>(
          value: _focusedDay.year,
          items: _years
              .map(
                (anio) => DropdownMenuItem<int>(
              value: anio,
              child: Text(anio.toString()),
            ),
          )
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            _navegarAFecha(DateTime(val, _focusedDay.month, 1));
          },
        ),
        const SizedBox(width: 4),
        _buildBotonCambioMes(
          icono: Icons.chevron_right_rounded,
          habilitado: puedeIrSiguiente,
          onPressed: () => _cambiarMes(1),
        ),
      ],
    );
  }

  Widget _buildCalendario() {
    return TableCalendar(
      locale: 'es',
      firstDay: _primerMesPermitido,
      key: keyCalendario,
      lastDay: _ultimoMesPermitido,
      focusedDay: _focusedDay,
      headerVisible: false,
      availableGestures: AvailableGestures.horizontalSwipe,
      onPageChanged: _navegarAFecha,
      startingDayOfWeek: StartingDayOfWeek.monday,
      eventLoader: (day) {
        final fechaNormalizada = fu.normalizarFecha(day);
        final hoy = fu.normalizarFecha(DateTime.now());

        final esMesVisible =
            fechaNormalizada.month == _focusedDay.month &&
                fechaNormalizada.year == _focusedDay.year;

        if (!esMesVisible) {
          return const [];
        }

        if (fechaNormalizada.isBefore(hoy)) {
          return const [];
        }

        return _eventosMap[fechaNormalizada] ?? const [];
      },
      enabledDayPredicate: (day) {
        final fechaNormalizada = fu.normalizarFecha(day);

        return fechaNormalizada.month == _focusedDay.month &&
            fechaNormalizada.year == _focusedDay.year;
      },
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        final hoy = fu.normalizarFecha(DateTime.now());
        final fechaSeleccionada = fu.normalizarFecha(selectedDay);

        if (fechaSeleccionada.isBefore(hoy)) return;

        setState(() {
          _selectedDay = fu.normalizarFecha(selectedDay);
          _focusedDay = fu.normalizarFecha(focusedDay);
        });
      },
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: _cs.onSurface.withValues(alpha: 128)),
        weekendStyle: TextStyle(color: _cs.onSurface.withValues(alpha: 128)),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,
        defaultTextStyle: TextStyle(color: _cs.onSurface),
        weekendTextStyle: TextStyle(color: _cs.onSurface),
        outsideTextStyle: TextStyle(
          color: _cs.onSurface.withValues(alpha: 0.35),
        ),
        todayDecoration: BoxDecoration(
          color: _cs.secondary,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: _cs.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: _cs.primary,
          shape: BoxShape.circle,
        ),
        markerMargin: const EdgeInsets.only(top: 3.8),
        markersAlignment: Alignment.bottomCenter,
        markersMaxCount: 1,
        selectedTextStyle: TextStyle(color: _cs.surface),
        todayTextStyle: TextStyle(color: _cs.surface),
      ),
    );
  }

  Widget _buildEventoBadge(String texto) {
    return Container(
      width: 100,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _cs.primary.withValues(alpha: 20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cs.primary.withValues(alpha: 64)),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: _cs.surface,
        ),
      ),
    );
  }

  Widget _buildEventoCard(Evento evento) {
    final fechaSeleccionada = fu.normalizarFecha(_selectedDay ?? _focusedDay);
    final etiquetaTiempo = _textoEtiquetaTiempo(evento, fechaSeleccionada);
    final textoFecha = _textoFechaCard(evento);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shadowColor: _cs.onSecondary.withValues(alpha: 0.18),
      color: _cs.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _cs.onSecondary.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        onTap: () => _abrirModalEvento(evento),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minLeadingWidth: 96,
        leading: _buildEventoBadge(etiquetaTiempo),
        title: Text(
          evento.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (evento.localizacion.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                evento.localizacion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 2),
            Text(
              textoFecha,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoCentro({required IconData icono, required String mensaje, Widget? accion}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 42, color: _cs.primary),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            if (accion != null) ...[
              const SizedBox(height: 12),
              accion,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventoLista() {
    if (_cargandoEventos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensajeError != null) {
      return _buildEstadoCentro(
        icono: Icons.wifi_off,
        mensaje: _mensajeError!,
        accion: TextButton(
          onPressed: _cargarEventos,
          child: const Text('Reintentar'),
        ),
      );
    }

    final lista = _eventosDelDiaSeleccionado();

    if (lista.isEmpty) {
      return _buildEstadoCentro(
        icono: Icons.event_busy,
        mensaje: 'No hay eventos para este día',
      );
    }

    return Stack(
      children: [
        Positioned(
          top: 6,
          bottom: 18,
          right: 4,
          child: Container(
            width: 6,
            decoration: BoxDecoration(
              color: _cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RawScrollbar(
            controller: _eventosScrollController,
            thumbVisibility: true,
            trackVisibility: false,
            interactive: true,
            thickness: 6,
            radius: const Radius.circular(20),
            mainAxisMargin: 6,
            crossAxisMargin: 4,
            thumbColor: _cs.primary,
            child: ListView.separated(
              key: keyListadoEventos,
              controller: _eventosScrollController,
              itemCount: lista.length,
              padding: const EdgeInsets.only(right: 10),
              itemBuilder: (context, index) {
                final evento = lista[index];
                return _buildEventoCard(evento);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 0),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TUTORIAL
  // ===========================================================================

  void _comprobarInicializacionTutorial() {
    if (!mounted) return;
    if (Tutorial.numPantalla != 3) return;
    if (Tutorial.tutorialInicializado) return;
    if (!_targetEstaListo(keyCalendario) && !_targetEstaListo(keyListadoEventos)) {
      return;
    }

    Tutorial.tutorialInicializado = true;
    _configurarTutorial();
  }

  void _configurarTutorial() {
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
    Tutorial.navPasoActivo.value = false;

    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: keyCalendario,
        titulo: 'Calendario',
        descripcion:
        'Aquí puedes ver los días del mes. Los días con eventos disponibles se marcarán con un punto en el calendario.',
        icon: Icons.calendar_month,
        siguiente: true,
        onNext: () => Tutorial.tutorial.next(),
        forma: ShapeLightFocus.RRect,
      ),
    );

    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: keyListadoEventos,
        titulo: 'Eventos del día seleccionado',
        descripcion:
        'En esta sección se muestra un listado de los eventos correspondientes al día que selecciones en el calendario. Al pulsar sobre cualquier evento puedes ver todos sus detalles.',
        icon: Icons.list_alt,
        siguiente: true,
        onNext: () => Tutorial.tutorial.next(),
        forma: ShapeLightFocus.RRect,
        alineamientoTarjeta: ContentAlign.top,
      ),
    );

    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: Tutorial.keyNavPerfil,
        titulo: 'Perfil',
        descripcion: 'Por último vamos a la sección de perfil.',
        icon: Icons.person,
        siguiente: true,
        onNext: () async {
          Tutorial.navPasoActivo.value = false;
          Tutorial.numPantalla = 4;
          Tutorial.tutorialInicializado = false;
          Tutorial.tutorial.finish();

          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          context.go(AppRoutes.perfil);
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
      body: Column(
        children: [
          const SizedBox(height: 12),

          // SELECTORES DE MES Y AÑO
          _buildSelectoresFecha(),
          const SizedBox(height: 12),

          // CALENDARIO
          _buildCalendario(),
          const SizedBox(height: 12),
          const Divider(),

          // LISTA DE EVENTOS
          Expanded(child: _buildEventoLista()),
        ],
      ),
    );
  }
}