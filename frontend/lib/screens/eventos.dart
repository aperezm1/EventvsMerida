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
                            child: Image.network(
                              evento.foto,
                              fit: BoxFit.cover,
                              alignment:
                                  .topCenter,
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
                                evento.titulo,
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
                                evento.localizacion,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14
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
                                      'Fecha: ${evento.fechaHora.day.toString().padLeft(2, '0')}/${evento.fechaHora.month.toString().padLeft(2, '0')}/${evento.fechaHora.year}',
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
                                      'Hora: ${evento.fechaHora.hour.toString().padLeft(2, '0')}:${evento.fechaHora.minute.toString().padLeft(2, '0')}',
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
    Usuario? usuario
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    bool estaGuardado = comprobarEstadoEvento(evento);

    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
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
                                        evento.titulo,
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
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: .start,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () => _abrirEnGoogleMaps(evento.localizacion),
                                                  icon: const Icon(
                                                    Icons.place_outlined,
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                                  label: Text(
                                                    evento.localizacion,
                                                    style: textTheme.bodyMedium?.copyWith(
                                                      decoration: .underline
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    alignment: Alignment.centerLeft,
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ),
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
                                            '${evento.fechaHora.day.toString().padLeft(2, '0')}/${evento.fechaHora.month.toString().padLeft(2, '0')}/${evento.fechaHora.year}',
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
                                            '${evento.fechaHora.hour.toString().padLeft(2, '0')}:${evento.fechaHora.minute.toString().padLeft(2, '0')}',
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
                                                        ? Icons.check
                                                        : Icons
                                                              .delete,
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

  Future<void> _abrirEnGoogleMaps(String direccion) async {
    final limpia = direccion.trim();
    final query = Uri.encodeComponent(limpia);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps')),
      );
    }
  }

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
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: colorScheme.surface.withValues(alpha: 0.98),
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
