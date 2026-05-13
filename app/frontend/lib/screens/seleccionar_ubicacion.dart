import 'package:eventvsmerida/widgets/componentes_compartidos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../services/geocoding_service.dart';

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
  String? _direccionSeleccionada;
  bool _cargandoDireccion = false;
  int _peticionDireccion = 0;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _puntoSeleccionado = widget.puntoInicial;

    if (_puntoSeleccionado != null) {
      _resolverDireccion(_puntoSeleccionado!);
    }
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

  Future<void> _resolverDireccion(LatLng punto) async {
    final idPeticion = ++_peticionDireccion;

    setState(() {
      _cargandoDireccion = true;
      _direccionSeleccionada = null;
    });

    final direccion = await GeocodingService.buscarDireccionDesdeCoordenadas(
      punto.latitude,
      punto.longitude,
    );

    if (!mounted || idPeticion != _peticionDireccion) {
      return;
    }

    setState(() {
      _cargandoDireccion = false;
      _direccionSeleccionada = direccion;
    });
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

                _resolverDireccion(point);
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _puntoSeleccionado == null
                          ? 'Pulsa en el mapa para seleccionar la ubicación exacta'
                          : _direccionSeleccionada != null
                          ? _direccionSeleccionada!
                          : _cargandoDireccion
                          ? 'Buscando el nombre de la calle...'
                          : 'No se ha podido obtener el nombre de la ubicación',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: _puntoSeleccionado == null
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    if (_puntoSeleccionado != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Latitud: ${_puntoSeleccionado!.latitude.toStringAsFixed(6)} · '
                        'Longitud: ${_puntoSeleccionado!.longitude.toStringAsFixed(6)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _cs.onSurface.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_cargandoDireccion) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _cs.primary,
                        ),
                      ),
                    ],
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