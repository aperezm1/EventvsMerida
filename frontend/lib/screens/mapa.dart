import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Mapa extends StatefulWidget {
  const Mapa({super.key});

  @override
  State<Mapa> createState() => _MapaState();
}

class _MapaState extends State<Mapa> {

  @override
  Widget build(BuildContext context) {
    Future.microtask(() => _mostrarProximamente(context));

    return Scaffold(
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(38.9161, -6.3437), // Mérida
          initialZoom: 14.0,
        ),
        children: [
          TileLayer( // Esta capa descarga los trozos del mapa
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.tuapp.merida',
          ),
          MarkerLayer( // Añadimos una marca en Mérida
            markers: [
              Marker(
                point: const LatLng(38.9161, -6.3437),
                width: 80,
                height: 80,
                child: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
  void _mostrarProximamente(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aviso'),
        content: Text('Próximamente...'),
      ),
    );
  }
}