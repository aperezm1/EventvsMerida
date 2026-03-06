import 'package:eventvsmerida/models/evento.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:ui';

class Eventos extends StatefulWidget {
  const Eventos({super.key});

  @override
  State<Eventos> createState() => _EventosState();
}

class _EventosState extends State<Eventos> {
  late Future<List<Evento>> _eventos;
  String fechaHora = "";

  @override
  void initState() {
    super.initState();
  }

  void _probarBoton() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Botón funcionando")));
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
                  onPressed: _probarBoton,
                  icon: Icon(Icons.search, color: colorScheme.primary),
                  tooltip: "Buscar",
                ),
                IconButton(
                  onPressed: null,
                  icon: Icon(
                    Icons.filter_alt_rounded,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  tooltip: "Filtrar",
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<dynamic>>(
          future: ApiService.obtenerEventos(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, indice) {
                final evento = snapshot.data![indice];
                final String tituloStr = evento['titulo'];
                if (tituloStr.contains("\\")) {
                  tituloStr.replaceAll("\\", "");
                }

                final String fechaHoraStr = evento['fechaHora'] ?? '';
                String fechaFormateada = '';
                String horaFormateada = '';
                String ubicacionFinal = '';

                if (fechaHoraStr.contains('T')) {
                  final partes = fechaHoraStr.split(
                    'T',
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

                  final String ubicacion = evento['localizacion'];
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
                  child: GestureDetector(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            evento['foto'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
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
                                evento['nombreCategoria'],
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
                      fechaFormateada,
                      ubicacionFinal,
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

  void _abrirModal(BuildContext context, dynamic evento, String fechaFormateada, String localizacionFormateada) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog<bool>(
      context: context,
      builder: (ctx) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          Center(
            child: AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.onPrimary,
                  width: 2,
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              contentPadding: const EdgeInsets.all(16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Icon(Icons.close),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sí'),
                ),
              ],
              actionsAlignment: MainAxisAlignment.start,
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(evento['foto'], width: 500, fit: BoxFit.cover),
                      const SizedBox(height: 16),
                      Text(
                        evento['titulo'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        evento['descripcion'],
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(localizacionFormateada),
                      Text(fechaFormateada),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}