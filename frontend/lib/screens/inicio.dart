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

  @override
  void initState() {
    super.initState();
    _eventos = ApiService.getEventos();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('dsfldsk'),
        backgroundColor: colorScheme.primary,
      ),
      body: FutureBuilder<List<Evento>>(
        future: _eventos,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay datos'));
          }

          final eventos = snapshot.data!;

          return ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (context, indice) {
              final evento = eventos[indice];

              return ListTile(
                title: Text(evento.nombre),
                subtitle: Text(
                  evento.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: CircleAvatar(child: Text(evento.id.toString())),
              );
            },
          );
        },
      ),
    );
  }
}
