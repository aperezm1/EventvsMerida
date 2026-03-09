import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/evento.dart';
import '../services/api_service.dart';

class Calendario extends StatefulWidget {
  const Calendario({super.key});

  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  late final DateTime _primerMesPermitido;
  late final DateTime _ultimoMesPermitido;
  late final List<int> _years;

  late DateTime _focusedDay;
  DateTime? _selectedDay;

  Map<DateTime, List<Evento>> _eventosMap = {};

  final List<String> _months = [
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
    'Diciembre'
  ];

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
            (index) => _primerMesPermitido.year + index
    );
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    try {
      final mapa = await ApiService.obtenerEventosParaCalendario();
      setState(() {
        _eventosMap = mapa;
      });
    } catch (e, stack) {
      debugPrint("Error cargando eventos: $e");
      debugPrintStack(stackTrace: stack);
    }
  }

  bool _esAntesDelPrimerMes(DateTime fecha) {
    final mes = DateTime(fecha.year, fecha.month, 1);
    return mes.isBefore(_primerMesPermitido);
  }

  bool _esDespuesDelUltimoMes(DateTime fecha) {
    final mes = DateTime(fecha.year, fecha.month, 1);
    return mes.isAfter(_ultimoMesPermitido);
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  List<DropdownMenuItem<int>> _buildMonthItems() {
    int mesInicio = 1;
    int mesFin = 12;

    if (_focusedDay.year == _primerMesPermitido.year) {
      mesInicio = _primerMesPermitido.month;
    }

    if (_focusedDay.year == _ultimoMesPermitido.year) {
      mesFin = _ultimoMesPermitido.month;
    }

    return List.generate(
      mesFin - mesInicio + 1,
          (index) {
        final mes = mesInicio + index;
        return DropdownMenuItem<int>(
          value: mes,
          child: Text(_months[mes - 1]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 60),
        // --- SECCIÓN DE SELECTORES ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDropdown(
              value: _focusedDay.month,
              items: _buildMonthItems(),
              onChanged: (val) {
                if (val == null) return;
                final nuevaFecha = DateTime(_focusedDay.year, val, 1);
                if (_esAntesDelPrimerMes(nuevaFecha)) {
                  _mostrarMensaje('No puedes ir a meses anteriores al actual');
                  return;
                }
                if (_esDespuesDelUltimoMes(nuevaFecha)) {
                  _mostrarMensaje('No puedes avanzar más allá de diciembre de 2030');
                  return;
                }
                setState(() {
                  _focusedDay = nuevaFecha;
                  _selectedDay = nuevaFecha;
                });
              },
            ),
            const SizedBox(width: 15),
            _buildDropdown(
              value: _focusedDay.year,
              items: _years.map((y) => DropdownMenuItem(
                value: y,
                child: Text(y.toString()),
              )).toList(),
              onChanged: (val) {
                if (val == null) return;
                final nuevaFecha = DateTime(val, _focusedDay.month, 1);
                if (_esAntesDelPrimerMes(nuevaFecha)) {
                  _mostrarMensaje('No puedes ir a meses anteriores al actual');
                  return;
                }
                if (_esDespuesDelUltimoMes(nuevaFecha)) {
                  _mostrarMensaje('No puedes avanzar más allá de diciembre de 2030');
                  return;
                }
                setState(() {
                  _focusedDay = nuevaFecha;
                  _selectedDay = nuevaFecha;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        TableCalendar(
          firstDay: _primerMesPermitido,
          lastDay: _ultimoMesPermitido,
          focusedDay: _focusedDay,
          headerVisible: false, // Desactivamos el header nativo
          availableGestures: AvailableGestures.none,
          //Función que carga los eventos para cada día
          eventLoader: (day) {
            // Normalizamos la fecha (sin horas) para buscar en el mapa
            final fechaNormalizada = DateTime(day.year, day.month, day.day);
            return _eventosMap[fechaNormalizada] ?? [];
          },

          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          /*onPageChanged: (focusedDay) {
            // Esto actualiza los dropdowns si el usuario desliza lateralmente
            setState(() => _focusedDay = focusedDay);
          },*/
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
                color: colorScheme.secondary,
                shape: BoxShape.circle
            ),
            selectedDecoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle
            ),
            markersAlignment: Alignment.bottomCenter,
            selectedTextStyle: TextStyle(color: colorScheme.onPrimary),
            todayTextStyle: TextStyle(color: colorScheme.onSecondary),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        Expanded(
          child: _buildEventoLista(),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEventoLista() {
    final fechaSeleccionada = _selectedDay ?? _focusedDay;
    //final eventosDia = _eventosMap[DateTime(fechaSeleccionada.year, fechaSeleccionada.month, fechaSeleccionada.day)];
    final fechaNormalizada = DateTime(
      fechaSeleccionada.year,
      fechaSeleccionada.month,
      fechaSeleccionada.day,
    );
    final lista = _eventosMap[fechaNormalizada] ?? [];

    if(lista.isEmpty) {
      return Center(
        child: Text("No hay eventos para este día"),
      );
    }

    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final evento = lista[index];
        final String hora = DateFormat('HH:mm').format(evento.fechaHora);
        //return ListTile(
        return Card(
          child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: .circular(8)
            ),
            child: Text(
              hora,
              style: TextStyle(
                  fontWeight: .bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer
              ),
            ),
          ),
          title: Text(evento.titulo),
          subtitle: Text(evento.localizacion),
          ),
        );
      }
    );
  }
}
