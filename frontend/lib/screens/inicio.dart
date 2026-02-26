import 'dart:ffi';

import 'package:eventvsmerida/models/evento.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  late Future<List<Evento>> _eventos;
  String fechaHora = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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

                if (fechaHoraStr.contains('T')) {
                  final partes = fechaHoraStr.split('T');      // ["2026-02-25", "18:30:00"]
                  final fecha = partes[0];                     // "2026-02-25"
                  final horaCompleta = partes[1];              // "18:30:00"

                  // Fecha a dd/MM/yyyy
                  final fechaPartes = fecha.split('-');        // ["2026", "02", "25"]
                  if (fechaPartes.length == 3) {
                    final anio = fechaPartes[0];
                    final mes = fechaPartes[1];
                    final dia = fechaPartes[2];
                    fechaFormateada = '$dia/$mes/$anio';       // "25/02/2026"
                  }

                  // Solo hora y minutos
                  final horaPartes = horaCompleta.split(':');  // ["18", "30", "00"]
                  if (horaPartes.length >= 2) {
                    final hh = horaPartes[0];
                    final mm = horaPartes[1];
                    horaFormateada = '$hh:$mm';                // "18:30"
                  }
                }
                return Card(
                  elevation: 6,
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: .circular(16)),
                  color: colorScheme.secondary,
                  child: Column(
                    mainAxisAlignment: .center,
                    mainAxisSize: .min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
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
                        padding: EdgeInsets.all(15),
                        child: Column(
                          mainAxisAlignment: .center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  tituloStr,
                                  style: TextStyle(fontWeight: .bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(evento['nombreCategoria']),
                              ],
                            ),
                            Row(
                              children: [
                                Text(evento['localizacion']),
                                const SizedBox(width: 15),
                                Text('Fecha: $fechaFormateada', softWrap: true),
                                const SizedBox(width: 15),
                                Text('Hora: $horaFormateada', softWrap: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
