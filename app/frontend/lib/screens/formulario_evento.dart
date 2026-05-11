import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../core/router/app_routes.dart';
import '../models/categoria.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/geocoding_service.dart';
import '../services/shared_preferences_service.dart';

class FormularioEvento extends StatefulWidget {
  final Evento? evento;

  const FormularioEvento({super.key, this.evento});

  bool get esEdicion => evento != null;

  @override
  State<FormularioEvento> createState() => _FormularioEventoState();
}

class _FormularioEventoState extends State<FormularioEvento> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _localizacionController = TextEditingController();

  Usuario? _usuario;
  bool _guardando = false;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  XFile? _imagenSeleccionada;
  final ImagePicker _imagePicker = ImagePicker();

  double? _latitudSeleccionada;
  double? _longitudSeleccionada;
  String _ultimaLocalizacionBuscada = '';

  List<Categoria> _categorias = [];
  Categoria? _categoriaSeleccionada;
  bool _cargandoCategorias = true;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarCategorias();
    _rellenarDatosSiEsEdicion();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _localizacionController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    final usuario = await SharedPreferencesService.cargarUsuario();

    if (!mounted) return;

    setState(() {
      _usuario = usuario;
    });
  }

  Future<void> _cargarCategorias() async {
    final respuesta = await ApiService.obtenerCategorias();

    if (!mounted) return;

    if (!respuesta.exito) {
      setState(() {
        _cargandoCategorias = false;
      });

      _mostrarMensaje(respuesta.mensaje);
      return;
    }

    final categorias = respuesta.datos ?? [];

    Categoria? categoriaDelEvento;

    if (widget.evento != null) {
      for (final categoria in categorias) {
        if (categoria.nombre == widget.evento!.nombreCategoria) {
          categoriaDelEvento = categoria;
          break;
        }
      }
    }

    setState(() {
      _categorias = categorias;
      _categoriaSeleccionada = categoriaDelEvento ??
          (categorias.isNotEmpty ? categorias.first : null);
      _cargandoCategorias = false;
    });
  }

  void _rellenarDatosSiEsEdicion() {
    final evento = widget.evento;

    if (evento == null) return;

    _tituloController.text = evento.titulo;
    _descripcionController.text = evento.descripcion;
    _fechaInicio = evento.fechaInicio;
    _fechaFin = evento.fechaFin;
    _localizacionController.text = evento.localizacion;
    _latitudSeleccionada = evento.latitud;
    _longitudSeleccionada = evento.longitud;

    _ultimaLocalizacionBuscada = evento.localizacion.trim();
  }

  Future<void> _seleccionarFechaHora({required bool esInicio}) async {
    final ahora = DateTime.now();

    final fechaInicial = esInicio
        ? (_fechaInicio ?? ahora)
        : (_fechaFin ?? _fechaInicio ?? ahora);

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: DateTime(2035, 12, 31),
    );

    if (fecha == null || !mounted) return;

    final horaInicial = TimeOfDay.fromDateTime(fechaInicial);

    final hora = await showTimePicker(
      context: context,
      initialTime: horaInicial,
    );

    if (hora == null || !mounted) return;

    final fechaHora = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    setState(() {
      if (esInicio) {
        _fechaInicio = fechaHora;

        if (_fechaFin != null && _fechaFin!.isBefore(fechaHora)) {
          _fechaFin = null;
        }
      } else {
        _fechaFin = fechaHora;
      }
    });
  }

  Future<void> _seleccionarImagen() async {
    final imagen = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (imagen == null || !mounted) return;

    final extension = imagen.path.toLowerCase();

    if (!extension.endsWith('.png') &&
        !extension.endsWith('.jpg') &&
        !extension.endsWith('.jpeg')) {
      _mostrarMensaje('Formato no válido. Usa PNG, JPG o JPEG.');
      return;
    }

    setState(() {
      _imagenSeleccionada = imagen;
    });
  }

  Future<void> _abrirSelectorUbicacion() async {
    final punto = await context.push<LatLng>(AppRoutes.seleccionarUbicacion);

    if (punto == null) return;


    setState(() {
      _latitudSeleccionada = punto.latitude;
      _longitudSeleccionada = punto.longitude;
      _ultimaLocalizacionBuscada = _localizacionController.text.trim();
    });
  }

  Future<void> _buscarUbicacionEnMapa() async {
    final localizacion = _localizacionController.text.trim();

    if (localizacion.isEmpty) {
      _mostrarMensaje('Escribe primero la localización');
      return;
    }

    final puntoEncontrado = await GeocodingService.buscarCoordenadas(localizacion);

    if (!mounted) return;

    if (puntoEncontrado == null) {
      _mostrarMensaje('No se encontró la ubicación. Selecciona el punto manualmente.');

      final puntoManual = await context.push<LatLng>(
        AppRoutes.seleccionarUbicacion,
      );

      if (puntoManual == null) return;

      setState(() {
        _latitudSeleccionada = puntoManual.latitude;
        _longitudSeleccionada = puntoManual.longitude;
        _ultimaLocalizacionBuscada = _localizacionController.text.trim();
      });

      return;
    }

    final puntoConfirmado = await context.push<LatLng>(
      AppRoutes.seleccionarUbicacion,
      extra: puntoEncontrado,
    );

    if (puntoConfirmado == null) return;

    setState(() {
      _latitudSeleccionada = puntoConfirmado.latitude;
      _longitudSeleccionada = puntoConfirmado.longitude;
      _ultimaLocalizacionBuscada = _localizacionController.text.trim();
    });
  }

  String? _validarObligatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }

    return null;
  }

  String _formatearFechaHora(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar';

    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  Map<String, dynamic> _crearBody() {
    return {
      'titulo': _tituloController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'fechaInicio': _fechaInicio!.toIso8601String(),
      'fechaFin': _fechaFin!.toIso8601String(),
      'localizacion': _localizacionController.text.trim(),
      'latitud': _latitudSeleccionada,
      'longitud': _longitudSeleccionada,
      'foto': '',
      'idUsuario': _usuario!.id,
      'idCategoria': _categoriaSeleccionada!.id,
    };
  }

  Future<void> _guardarEvento() async {
    if (_usuario == null) {
      _mostrarMensaje('No hay usuario logueado');
      return;
    }

    final rol = _usuario!.rol.trim().toLowerCase();

    if (rol != 'organizador' && rol != 'administrador') {
      _mostrarMensaje('Solo los usuarios organizadores o administradores pueden crear eventos');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSeleccionada == null) {
      _mostrarMensaje('Selecciona una categoría');
      return;
    }

    if (_fechaInicio == null) {
      _mostrarMensaje('Selecciona la fecha y hora de inicio');
      return;
    }

    if (_fechaFin == null) {
      _mostrarMensaje('Selecciona la fecha y hora de fin');
      return;
    }

    if (_fechaFin!.isBefore(_fechaInicio!)) {
      _mostrarMensaje('La fecha de fin no puede ser anterior a la fecha de inicio');
      return;
    }

    if (_latitudSeleccionada == null || _longitudSeleccionada == null) {
      _mostrarMensaje('Selecciona el punto exacto en el mapa');
      return;
    }

    if (_latitudSeleccionada != null &&
        _longitudSeleccionada != null &&
        _localizacionController.text.trim() != _ultimaLocalizacionBuscada) {
      _mostrarMensaje('Has cambiado la localización. Vuelve a buscar o seleccionar el punto en el mapa.');
      return;
    }

    if (!widget.esEdicion && _imagenSeleccionada == null) {
      _mostrarMensaje('Debes seleccionar una imagen para el evento');
      return;
    }

    setState(() {
      _guardando = true;
    });

    final respuesta = widget.esEdicion
      ? await ApiService.actualizarEventoConImagen(
        widget.evento!.id,
        _crearBody(),
        _imagenSeleccionada,
      )
      : await ApiService.crearEventoConImagen(
        _crearBody(),
        _imagenSeleccionada!,
    );

    if (!mounted) return;

    setState(() {
      _guardando = false;
    });

    _mostrarMensaje(respuesta.mensaje);

    if (respuesta.exito) {
      Navigator.of(context).pop(true);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  InputDecoration _decoracion(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cs.primary, width: 2),
      ),
    );
  }

  Widget _selectorCategoria() {
    if (_cargandoCategorias) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_categorias.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InputDecorator(
          decoration: _decoracion('Categoría'),
          child: Text(
            'No hay categorías disponibles',
            style: TextStyle(color: _cs.error),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<Categoria>(
        initialValue: _categoriaSeleccionada,
        decoration: _decoracion('Categoría'),
        items: _categorias.map((categoria) {
          return DropdownMenuItem<Categoria>(
            value: categoria,
            child: Text(categoria.nombre),
          );
        }).toList(),
        onChanged: (categoria) {
          setState(() {
            _categoriaSeleccionada = categoria;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Selecciona una categoría';
          }
          return null;
        },
      ),
    );
  }

  Widget _selectorFechaHora({
    required String titulo,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: InputDecorator(
          decoration: _decoracion(titulo),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatearFechaHora(fecha),
                style: TextStyle(color: _cs.onSurface),
              ),
              Icon(Icons.calendar_month, color: _cs.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoTexto({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: _validarObligatorio,
        decoration: _decoracion(label),
      ),
    );
  }

  Widget _selectorImagen() {
    final nombreImagen = _imagenSeleccionada != null
      ? _imagenSeleccionada!.name
      : widget.esEdicion
        ? 'Mantener imagen actual'
        : 'Seleccionar imagen';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _seleccionarImagen,
        child: InputDecorator(
          decoration: _decoracion('Imagen del evento'),
          child: Row(
            children: [
              Icon(Icons.image, color: _cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nombreImagen,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _cs.onSurface),
                ),
              ),
              Icon(Icons.upload_file, color: _cs.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectorUbicacionMapa() {
    final texto = _latitudSeleccionada == null || _longitudSeleccionada == null
        ? 'Seleccionar ubicación en el mapa'
        : 'Ubicación seleccionada\n'
        'Lat: ${_latitudSeleccionada!.toStringAsFixed(6)} · '
        'Lng: ${_longitudSeleccionada!.toStringAsFixed(6)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _abrirSelectorUbicacion,
        child: InputDecorator(
          decoration: _decoracion('Punto en el mapa'),
          child: Row(
            children: [
              Icon(Icons.map, color: _cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(color: _cs.onSurface),
                ),
              ),
              Icon(Icons.location_on, color: _cs.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonBuscarUbicacion() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _buscarUbicacionEnMapa,
          icon: const Icon(Icons.search),
          label: const Text('Buscar localización en el mapa'),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _campoTexto(
            label: 'Título',
            controller: _tituloController,
          ),
          _campoTexto(
            label: 'Descripción',
            controller: _descripcionController,
            maxLines: 4,
          ),
          _selectorFechaHora(
            titulo: 'Fecha y hora de inicio',
            fecha: _fechaInicio,
            onTap: () => _seleccionarFechaHora(esInicio: true),
          ),
          _selectorFechaHora(
            titulo: 'Fecha y hora de fin',
            fecha: _fechaFin,
            onTap: () => _seleccionarFechaHora(esInicio: false),
          ),
          _campoTexto(
            label: 'Localización',
            controller: _localizacionController,
          ),
          _botonBuscarUbicacion(),
          _selectorUbicacionMapa(),
          _selectorImagen(),
          _selectorCategoria(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardarEvento,
              icon: _guardando
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
              label: Text(_guardando ? 'Guardando...'
                  : widget.esEdicion
                    ? 'Actualizar evento'
                    : 'Guardar evento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cs.primary,
                foregroundColor: _cs.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cs.surface,
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar evento' : 'Añadir evento'),
        backgroundColor: _cs.primary,
        foregroundColor: _cs.surface,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _buildFormulario(),
      ),
    );
  }
}