import 'package:eventvsmerida/widgets/componentes_compartidos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

class SeleccionarUbicacion extends StatefulWidget {
  final LatLng? puntoInicial;

  const SeleccionarUbicacion({super.key, this.puntoInicial});

  @override
  State<SeleccionarUbicacion> createState() => _SeleccionarUbicacionState();
}

class _SeleccionarUbicacionState extends State<SeleccionarUbicacion> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  static const LatLng _merida = LatLng(38.9161, -6.3437);

  LatLng? _puntoSeleccionado;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _puntoSeleccionado = widget.puntoInicial;
  }

  LatLng get _centroInicial => widget.puntoInicial ?? _merida;

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  void _confirmarUbicacion() {
    if (_puntoSeleccionado == null) {
      Mensaje.mostrarSnackBar(context: context, mensaje: 'Pulsa un punto del mapa', icon: Icons.map, color: _cs.error);
      return;
    }

    context.pop(_puntoSeleccionado);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cs.surface,
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        backgroundColor: _cs.primary,
        foregroundColor: _cs.surface,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmarUbicacion,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _centroInicial,
              initialZoom: widget.puntoInicial == null ? 15 : 17,
              onTap: (tapPosition, point) {
                setState(() {
                  _puntoSeleccionado = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'es.nullpointers.eventvsmerida',
              ),
              if (_puntoSeleccionado != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _puntoSeleccionado!,
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.location_on,
                        size: 50,
                        color: _cs.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _puntoSeleccionado == null
                      ? 'Pulsa en el mapa para seleccionar la ubicación exacta'
                      : 'Latitud: ${_puntoSeleccionado!.latitude.toStringAsFixed(6)}\n'
                      'Longitud: ${_puntoSeleccionado!.longitude.toStringAsFixed(6)}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}