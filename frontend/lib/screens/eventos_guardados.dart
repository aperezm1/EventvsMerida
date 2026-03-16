import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';
import '../models/usuario.dart';

class EventosGuardados extends StatefulWidget {
  const EventosGuardados({super.key});

  @override
  State<EventosGuardados> createState() => _EventosGuardadosState();
}

class _EventosGuardadosState extends State<EventosGuardados> {
  Usuario? _usuario;
  List<Evento> _eventos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final usuario = await SharedPreferencesService.cargarUsuario();
    final eventos = await ApiService.obtenerEventosGuardados(usuario!.email);

    setState(() {
      _usuario = usuario;
      _eventos = eventos;
      _cargando = false;
    });
  }

  Future<void> _borrarEvento(Evento evento) async {
    String mensaje = await ApiService.eliminarEventoUsuario(
      _usuario!.email,
      evento.titulo,
      evento.fechaHora,
    );

    if (mensaje == "Evento eliminado correctamente") {
      setState(() {
        _eventos.remove(evento);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(mensaje, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior:
        SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),
      ),
    );
  }

  // CABECERA
  Widget _cabecera(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      color: colorScheme.primary,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.surface.withOpacity(0.9),
            radius: 45,
            child: Icon(Icons.person, color: colorScheme.primary, size: 45),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.surface,
        centerTitle: true,
        title: const Text('Eventos guardados'),
        elevation: 2,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          // EN CASO DE NO HABER EVENTOS
          : _eventos.isEmpty
          ? Column(
              children: [
                _cabecera(colorScheme),
                Expanded(
                  child: Center(
                    child: Text(
                      'No tienes eventos guardados',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          // EN CASO DE HABER EVENTOS
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                _cabecera(colorScheme),
                const SizedBox(height: 16),

                // TARJETA EVENTO
                ..._eventos.map(
                  (evento) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.onPrimary.withAlpha(64),
                            blurRadius: 5,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),

                      // INFORMACIÓN DEL EVENTO
                      child: Row(
                        children: [
                          // IMAGEN DEL EVENTO
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                            ),
                            child: Image.network(
                              evento.foto,
                              width: 100,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 100,
                                    height: 90,
                                    color: colorScheme.secondary.withAlpha(51),
                                    child: Icon(
                                      Icons.image,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                            ),
                          ),

                          // CONTENIDO DEL EVENTO
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // TEXTO NOMBRE EVENTO
                                  Text(
                                    evento.titulo,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),

                                  // TEXTO LUGAR
                                  Text(
                                    evento.localizacion,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withAlpha(
                                        178,
                                      ),
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),

                                  // FECHA Y HORA
                                  Row(
                                    children: [
                                      // TEXTO FECHA
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${evento.fechaHora.day.toString().padLeft(2, '0')}/${evento.fechaHora.month.toString().padLeft(2, '0')}/${evento.fechaHora.year}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // TEXTO HORA
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${evento.fechaHora.hour.toString().padLeft(2, '0')}:${evento.fechaHora.minute.toString().padLeft(2, '0')}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // BOTÓN ELIMINAR
                          IconButton(
                            icon: Icon(Icons.delete, color: colorScheme.error),
                            onPressed: () => _borrarEvento(evento),
                            tooltip: 'Eliminar evento',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
