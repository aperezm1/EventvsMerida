import 'package:eventvsmerida/models/evento.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import 'dart:ui';

import '../services/shared_preferences_service.dart';

class Eventos extends StatefulWidget {
  const Eventos({super.key});

  @override
  State<Eventos> createState() => _EventosState();
}

class _EventosState extends State<Eventos> {
  late Future<List<Evento>> _eventos;
  String fechaHora = "";
  Usuario? _usuario;
  List<Evento> _eventosGuardados = [];

  void _cargarUsuario() async {
    final usuario = await SharedPreferencesService.cargarUsuario();
    setState(() {
      _usuario = usuario;
    });
  }

  Future<void> _cargarEventosGuardados(Usuario usuario) async {
    final eventos = await ApiService.obtenerEventosGuardados(usuario.email);
    _eventosGuardados = eventos;
  }

  Future<void> _cargarDatos() async {
    final usuario = await SharedPreferencesService.cargarUsuario();
    if (!mounted) return;
    setState(() {
      _usuario = usuario;
    });
    if (_usuario != null) {
      await _cargarEventosGuardados(_usuario!);
      if (!mounted) return;
      setState(() {}); // para que se reconstruya con la lista cargada
    }
  }

  @override
  void initState() {
    super.initState();
    _eventos = ApiService.obtenerEventos();
    _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onPrimary,
        title: SizedBox(
          height: 40,
          child: Image.asset(
            'assets/images/logo-eventvs-merida-no-bg.png',
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  onPressed: null,
                  icon: Icon(
                      Icons.search,
                      color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  tooltip: "Buscar - Próximamente",
                ),
                IconButton(
                  onPressed: null,
                  icon: Icon(
                    Icons.filter_alt_rounded,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  tooltip: "Filtrar - Próximamente",
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<Evento>>(
          future: _eventos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final eventos = snapshot.data!;
            return ListView.builder(
              itemCount: eventos.length,
              itemBuilder: (context, indice) {
                final evento = eventos[indice];
                final String tituloStr = evento.titulo;
                if (tituloStr.contains("\\")) {
                  tituloStr.replaceAll("\\", "");
                }

                final String fechaHoraStr = evento.fechaHora.toString() ?? '';
                String fechaFormateada = '';
                String horaFormateada = '';
                String ubicacionFinal = '';

                if (fechaHoraStr.contains(' ')) {
                  final partes = fechaHoraStr.split(
                    ' ',
                  ); // ["2026-02-25", "18:30:00"]
                  final fecha = partes[0]; // "2026-02-25"
                  final horaCompleta = partes[1]; // "18:30:00"

                  // Fecha a dd/MM/yyyy
                  final fechaPartes = fecha.split('-'); // ["2026", "02", "25"]
                  if (fechaPartes.length == 3) {
                    final anio = fechaPartes[0];
                    final mes = fechaPartes[1];
                    final dia = fechaPartes[2];
                    fechaFormateada = '$dia/$mes/$anio'; // "25/02/2026"
                  }

                  // Solo hora y minutos
                  final horaPartes = horaCompleta.split(
                    ':',
                  ); // ["18", "30", "00"]
                  if (horaPartes.length >= 2) {
                    final hh = horaPartes[0];
                    final mm = horaPartes[1];
                    horaFormateada = '$hh:$mm'; // "18:30"
                  }

                  final String ubicacion = evento.localizacion;
                  List<String> ubicacionParseada = ubicacion.split("");
                  for (int i = 0; i < ubicacionParseada.length; i++) {
                    if (ubicacionParseada[i] == '\\' &&
                        ubicacionParseada[i + 1] != 'n') {
                      ubicacionParseada[i] = ubicacionParseada[i].replaceAll(
                        '\\',
                        '',
                      );
                    }
                    ubicacionFinal += ubicacionParseada[i];
                  }
                }

                return Card(
                  elevation: 6,
                  shadowColor: colorScheme.onSurface,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.onPrimary, width: 2),
                  ),
                  color: colorScheme.secondary,
                  child: InkWell(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            // o 3/2, 4/3, etc. Elige la que mejor quede.
                            child: Image.network(
                              evento.foto,
                              fit: BoxFit.cover,
                              alignment:
                                  .topCenter, // rellena todo el espacio, recortando un poco si hace falta
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título
                              Text(
                                tituloStr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Categoría
                              Text(
                                evento.nombreCategoria,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),

                              // Localización
                              Text(
                                ubicacionFinal,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),

                              // Fecha y hora
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Fecha: $fechaFormateada',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Hora: $horaFormateada',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _abrirModal(
                      context,
                      evento,
                      _usuario,
                      tituloStr,
                      fechaFormateada,
                      ubicacionFinal,
                      horaFormateada,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _abrirModal(
    BuildContext context,
    Evento evento,
    Usuario? usuario,
    String tituloFormateado,
    String fechaFormateada,
    String localizacionFormateada,
    String horaFormateada,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    bool estaGuardado = comprobarEstadoEvento(evento);

    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          child: StatefulBuilder(
            builder: (dialogContext, setStateDialog) {
              return Stack(
                children: [
                  // Blur de fondo dentro del área del diálogo
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 500,
                          maxHeight: 700,
                        ),
                        child: Material(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  4,
                                  0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tituloFormateado,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      tooltip: 'Cerrar',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: 320,
                                          maxWidth: constraints.maxWidth,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          alignment: Alignment.topCenter,
                                          child: Image.network(evento.foto),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.place_outlined,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  localizacionFormateada,
                                                  style: textTheme.bodyMedium,
                                                ),
                                                const SizedBox(height: 4),
                                                // TextButton.icon(
                                                //   onPressed: () => _abrirEnGoogleMaps(localizacionFormateada),
                                                //   icon: const Icon(Icons.map_outlined),
                                                //   label: const Text('Abrir en Google Maps'),
                                                // ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            fechaFormateada,
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.access_time,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            horaFormateada,
                                            style: textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Descripción',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        evento.descripcion,
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // -------- BOTÓN ABAJO --------
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () async {
                                          if (usuario == null) {
                                            _mostrarModalNoLogeado(context);
                                            return;
                                          }

                                          setStateDialog(() {
                                            estaGuardado = !estaGuardado;
                                          });

                                          String respuesta;
                                          if (estaGuardado) {
                                            respuesta = await _guardarEvento(
                                              evento,
                                              usuario,
                                            );
                                          } else {
                                            respuesta = await _eliminarEvento(
                                              evento,
                                              usuario,
                                            );
                                          }

                                          // SnackBar SOBRE la modal
                                          ScaffoldMessenger.of(
                                            dialogContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    estaGuardado
                                                        ? Icons.bookmark
                                                        : Icons
                                                              .bookmark_border_outlined,
                                                    size: 20,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    respuesta,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: estaGuardado
                                                  ? Colors.green
                                                  : Colors.red,
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
                                        },
                                        icon: Icon(
                                          estaGuardado
                                              ? Icons.bookmark
                                              : Icons.bookmark_border_outlined,
                                        ),
                                        label: Text(
                                          estaGuardado
                                              ? 'Evento guardado'
                                              : 'Guardar evento',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Future<void> _abrirEnGoogleMaps(String direccion) async {
  //   final query = Uri.encodeComponent(direccion);
  //   final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
  //
  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(
  //       uri,
  //       mode: LaunchMode.externalApplication, // abre la app de Maps si puede
  //     );
  //   } else {
  //     // Opcional: mostrar SnackBar de error
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('No se pudo abrir Google Maps')),
  //     );
  //   }
  // }

  bool comprobarEstadoEvento(Evento evento) {
    // si Evento tiene id, usa ese campo; si no, comparar por título + fechaHora
    return _eventosGuardados.any((e) =>
    e.titulo == evento.titulo &&
    e.fechaHora == evento.fechaHora);
  }

  Future<String> _guardarEvento(Evento evento, Usuario usuario) async {
    final respuesta = await ApiService.guardarEventoUsuario(
      usuario.email,
      evento.titulo,
      evento.fechaHora,
    );

    if (respuesta == 'Evento guardado correctamente') {
      setState(() {
        // Comprobar si ya existe el evento en la lista
        final yaEsta = _eventosGuardados.any((e) =>
        e.titulo == evento.titulo && e.fechaHora == evento.fechaHora);
        if (!yaEsta) {
          _eventosGuardados.add(evento);
        }
      });
      return respuesta;
    }

    return 'Ha ocurrido un problema al guardar el evento';
  }

  Future<String> _eliminarEvento(Evento evento, Usuario usuario) async {
    final respuesta = await ApiService.eliminarEventoUsuario(
      usuario.email,
      evento.titulo,
      evento.fechaHora,
    );

    if (respuesta == 'Evento eliminado correctamente') {
      setState(() {
        _eventosGuardados.removeWhere((e) =>
        e.titulo == evento.titulo && e.fechaHora == evento.fechaHora);
      });
      return respuesta;
    }

    return 'Ha ocurrido un problema al eliminar el evento';
  }

  void _mostrarModalNoLogeado(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: colorScheme.surface.withOpacity(0.98),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono + título + botón cerrar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Inicia sesión o regístrate',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Para poder guardar un evento, tienes que iniciar sesión o registrarte.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary, // naranja
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            context.go('/registro');
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Registrarse'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.go('/login');
                            Navigator.of(ctx).pop();
                          },
                          child: const Text(
                            'Iniciar sesión',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
