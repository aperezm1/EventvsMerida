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
    final colorScheme = Theme.of(context).colorScheme;

    //Future.microtask(() => _mostrarProximamente(context));

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(38.9161, -6.3437), // Mérida
              initialZoom: 14.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.none,
              ),
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
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            top: 350,
            left: 8,
            right: 8,
            child: Material(
              elevation: 6,
              borderRadius: .circular(16),
              color: colorScheme.surface.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                      color: colorScheme.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                        child: Text('Proximamente...', style: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: .w600)),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}