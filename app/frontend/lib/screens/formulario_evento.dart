import 'package:eventvsmerida/utils/fecha_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../core/router/app_routes.dart';
import '../models/categoria.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/geocoding_service.dart';
import '../services/shared_preferences_service.dart';
import '../utils/validation_utils.dart';
import '../widgets/componentes_compartidos.dart';

class FormularioEvento extends StatefulWidget {
  final Evento? evento;

  const FormularioEvento({super.key, this.evento});

  bool get esEdicion => evento != null;

  @override
  State<FormularioEvento> createState() => _FormularioEventoState();
}

class _FormularioEventoState extends State<FormularioEvento> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _localizacionController = TextEditingController();
  final ScrollController _categoriasScrollController = ScrollController();
  final ScrollController _formularioScrollController = ScrollController();

  Usuario? _usuario;
  bool _guardando = false;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  XFile? _imagenSeleccionada;
  final ImagePicker _imagePicker = ImagePicker();

  double? _latitudSeleccionada;
  double? _longitudSeleccionada;
  int _peticionTextoUbicacion = 0;
  String _ultimaLocalizacionBuscada = '';

  List<Categoria> _categorias = [];
  Categoria? _categoriaSeleccionada;
  bool _cargandoCategorias = true;
  FechaUtils fu = FechaUtils();
  bool modalCategoriaAbierto = false;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

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
    _formularioScrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

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

      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: respuesta.mensaje,
        icon: Icons.close,
        color: _cs.error,
      );
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
      _categoriaSeleccionada ??= categoriaDelEvento;
      _cargandoCategorias = false;
    });
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

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

  Future<void> _actualizarTextoUbicacion(LatLng punto) async {
    final idPeticion = ++_peticionTextoUbicacion;

    final textoManual = _localizacionController.text.trim();

    final texto = await GeocodingService.buscarDireccionDesdeCoordenadas(
      punto.latitude,
      punto.longitude,
    );

    if (!mounted || idPeticion != _peticionTextoUbicacion) {
      return;
    }

    setState(() {
      if (texto != null && texto.trim().isNotEmpty) {
        final direccion = texto.trim();
        final combinado =
            textoManual.isNotEmpty &&
                !direccion.toLowerCase().contains(textoManual.toLowerCase())
            ? '$textoManual, $direccion'
            : direccion;
        final normalizado = _normalizarLocalizacion(combinado);
        _localizacionController.text = normalizado;
        _ultimaLocalizacionBuscada = normalizado;
      }
    });
  }

  String _normalizarLocalizacion(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return limpio;

    final palabras = limpio.split(RegExp(r'\s+'));
    final resultado = <String>[];
    String? anteriorNormalizada;

    for (final palabra in palabras) {
      final normalizada = palabra.toLowerCase().replaceAll(
        RegExp(r'[\.,;:]+'),
        '',
      );
      if (normalizada.isEmpty) {
        continue;
      }
      if (normalizada == anteriorNormalizada) {
        continue;
      }
      resultado.add(palabra);
      anteriorNormalizada = normalizada;
    }

    var combinado = resultado.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final partes = combinado
        .split(',')
        .map((parte) => parte.trim())
        .where((parte) => parte.isNotEmpty)
        .toList();
    final partesLimpias = <String>[];
    String? anteriorParte;
    for (final parte in partes) {
      final normalizada = parte.toLowerCase();
      if (normalizada == anteriorParte) {
        continue;
      }
      partesLimpias.add(parte);
      anteriorParte = normalizada;
    }
    if (partesLimpias.length > 2) {
      partesLimpias.removeRange(2, partesLimpias.length);
    }
    combinado = partesLimpias.join(', ').trim();
    final lower = combinado.toLowerCase();
    final contieneMerida = lower.contains('mérida') || lower.contains('merida');
    if (!contieneMerida) {
      combinado = '$combinado, Mérida';
    }
    return combinado;
  }

  Future<DateTime?> _seleccionarFechaHora({required bool esInicio}) async {
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

    if (fecha == null || !mounted) return null;

    final horaInicial = TimeOfDay.fromDateTime(fechaInicial);

    final hora = await showTimePicker(
      context: context,
      initialTime: horaInicial,
    );

    if (hora == null || !mounted) return null;

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

    return fechaHora;
  }

  Future<void> _seleccionarImagen() async {
    final imagen = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (imagen == null || !mounted) return;

    final ok = await ImageSize.validarTamanioImagen(imagen);

    if (!ok) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'La imagen no puede superar 1,5 MB',
        icon: Icons.image_not_supported_outlined,
        color: Colors.red,
      );
      return null;
    }

    final extension = imagen.path.toLowerCase();

    if (!extension.endsWith('.png') &&
        !extension.endsWith('.jpg') &&
        !extension.endsWith('.jpeg')) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'Formato no válido. Usa PNG, JPG o JPEG',
        icon: Icons.image_not_supported_outlined,
        color: _cs.error,
      );
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

    await _actualizarTextoUbicacion(punto);
  }

  Future<void> _buscarUbicacionEnMapa() async {
    final localizacion = _localizacionController.text.trim();

    if (localizacion.isEmpty) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'Escribe primero la localización',
        icon: Icons.map,
        color: _cs.error,
      );
      return;
    }

    final puntoEncontrado = await GeocodingService.buscarCoordenadas(
      localizacion,
    );

    if (!mounted) return;

    if (puntoEncontrado == null) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'No se encontró la ubicación. Selecciona el punto manualmente',
        icon: Icons.map,
        color: _cs.error,
      );

      final puntoManual = await context.push<LatLng>(
        AppRoutes.seleccionarUbicacion,
      );

      if (puntoManual == null) return;

      setState(() {
        _latitudSeleccionada = puntoManual.latitude;
        _longitudSeleccionada = puntoManual.longitude;
        _ultimaLocalizacionBuscada = _localizacionController.text.trim();
      });

      await _actualizarTextoUbicacion(puntoManual);

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

    await _actualizarTextoUbicacion(puntoConfirmado);
  }

  String? _validarObligatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }

    return null;
  }

  String? _validarFechaObligatoria(DateTime? value) {
    if (value == null) {
      return 'Selecciona una fecha';
    }

    return null;
  }

  String _formatearFechaHora(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar';

    return fu.formatearFechaHora(fecha);
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
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'No hay usuario logueado',
        icon: Icons.person,
        color: _cs.error,
      );
      return;
    }

    final rol = _usuario!.rol.trim().toLowerCase();

    if (rol != 'organizador' && rol != 'administrador') {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje:
            'Solo los usuarios organizadores o administradores pueden crear eventos',
        icon: Icons.person,
        color: _cs.error,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSeleccionada == null) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'Selecciona una categoría',
        icon: Icons.label,
        color: _cs.error,
      );
      return;
    }

    if (_fechaInicio == null) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'Selecciona la fecha y hora de inicio',
        icon: Icons.date_range,
        color: _cs.error,
      );
      return;
    }

    if (_fechaFin == null) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'Selecciona la fecha y hora de fin',
        icon: Icons.date_range,
        color: _cs.error,
      );
      return;
    }

    if (_fechaFin!.isBefore(_fechaInicio!)) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'La fecha de fin no puede ser anterior a la fecha de inicio',
        icon: Icons.date_range,
        color: _cs.error,
      );
      return;
    }

    if (_latitudSeleccionada == null || _longitudSeleccionada == null) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'Selecciona el punto exacto en el mapa',
        icon: Icons.map,
        color: _cs.error,
      );
      return;
    }

    if (_latitudSeleccionada != null &&
        _longitudSeleccionada != null &&
        _localizacionController.text.trim() != _ultimaLocalizacionBuscada) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje:
            'Has cambiado la localización. Vuelve a buscar o seleccionar el punto en el mapa.',
        icon: Icons.map,
        color: _cs.error,
      );
      return;
    }

    if (!widget.esEdicion && _imagenSeleccionada == null) {
      Mensaje.mostrarSnackBar(
        context: context,
        mensaje: 'Debes seleccionar una imagen para el evento',
        icon: Icons.image,
        color: _cs.error,
      );
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

    Mensaje.mostrarSnackBar(
      context: context,
      mensaje: respuesta.mensaje,
      icon: Icons.event_available,
      color: respuesta.exito ? Colors.green : _cs.error,
    );

    if (respuesta.exito) {
      Navigator.of(context).pop(true);
    }
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  InputDecoration _decoracion(String label, {Widget? labelWidget}) {
    return InputDecoration(
      label: labelWidget,
      labelText: labelWidget == null ? label : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cs.primary, width: 2),
      ),
    );
  }

  Widget _etiquetaCampo(String label, {required bool obligatorio}) {
    if (!obligatorio) {
      return Text(label);
    }

    return Text.rich(
      TextSpan(
        text: label,
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _selectorCategoria() {
    if (_cargandoCategorias) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Center(child: CircularProgressIndicator()),
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
      child: FormField<String>(
        validator: (_) {
          if (_categoriaSeleccionada == null) {
            return 'Selecciona una categoría';
          }

          return null;
        },
        builder: (FormFieldState<String> state) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                modalCategoriaAbierto = true;
              });

              _buildModalSeleccionarCategoria();
            },
            child: InputDecorator(
              decoration: _decoracion(
                'Categoría',
                labelWidget: _etiquetaCampo('Categoría', obligatorio: true),
              ).copyWith(errorText: state.errorText),
              child: Row(
                children: [
                  Icon(Icons.category, color: _cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _categoriaSeleccionada?.nombre ??
                          'Seleccione una categoría',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _categoriaSeleccionada == null
                            ? _cs.onSurface.withValues(alpha: 0.6)
                            : _cs.onSurface,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_outlined, color: _cs.primary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _selectorFechaHora({
    required String titulo,
    required DateTime? fecha,
    required Future<DateTime?> Function() onTap,
    String? Function(DateTime?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FormField<DateTime>(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        initialValue: fecha,
        validator: validator ?? _validarFechaObligatoria,
        builder: (FormFieldState<DateTime> state) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final nuevaFecha = await onTap();

              if (nuevaFecha != null) {
                state.didChange(nuevaFecha);
              }
            },
            child: InputDecorator(
              decoration: _decoracion(
                titulo,
                labelWidget: _etiquetaCampo(titulo, obligatorio: true),
              ).copyWith(errorText: state.errorText),
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
          );
        },
      ),
    );
  }

  Widget _campoTexto({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obligatorio = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: obligatorio ? _validarObligatorio : null,
        decoration: _decoracion(
          label,
          labelWidget: _etiquetaCampo(label, obligatorio: obligatorio),
        ),
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
      child: FormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (_) {
          if (!widget.esEdicion && _imagenSeleccionada == null) {
            return 'Selecciona una imagen';
          }

          return null;
        },
        builder: (FormFieldState state) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await _seleccionarImagen();

              state.didChange(_imagenSeleccionada);
            },
            child: InputDecorator(
              decoration: _decoracion(
                'Imagen del evento',
                labelWidget: _etiquetaCampo(
                  'Imagen del evento',
                  obligatorio: true,
                ),
              ).copyWith(errorText: state.errorText),
              child: Row(
                children: [
                  Icon(Icons.image, color: _cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nombreImagen,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _imagenSeleccionada == null && !widget.esEdicion
                            ? _cs.onSurface.withValues(alpha: 0.6)
                            : _cs.onSurface,
                      ),
                    ),
                  ),
                  Icon(Icons.upload_file, color: _cs.primary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _selectorUbicacionMapa() {
    final texto = _latitudSeleccionada == null || _longitudSeleccionada == null
        ? 'Seleccionar ubicación en el mapa'
        : 'Lat: ${_latitudSeleccionada!.toStringAsFixed(6)} · '
              'Lng: ${_longitudSeleccionada!.toStringAsFixed(6)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _abrirSelectorUbicacion,
        child: InputDecorator(
          decoration: _decoracion(
            'Punto en el mapa',
            labelWidget: _etiquetaCampo('Punto en el mapa', obligatorio: true),
          ),
          child: Row(
            children: [
              Icon(Icons.map, color: _cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(texto, style: TextStyle(color: _cs.onSurface)),
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

  Widget _seccionFormulario({
    required String titulo,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: Column(
        children: [
          _seccionFormulario(
            titulo: 'Información del evento',
            children: [
              _campoTexto(
                label: 'Título',
                controller: _tituloController,
                obligatorio: true,
              ),
              _campoTexto(
                label: 'Descripción',
                controller: _descripcionController,
                maxLines: 4,
              ),
              _selectorCategoria(),
            ],
          ),

          _seccionFormulario(
            titulo: 'Fecha del evento',
            children: [
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
            ],
          ),
          _seccionFormulario(
            titulo: 'Ubicación del evento',
            children: [
              _campoTexto(
                label: 'Localización',
                controller: _localizacionController,
              ),
              _botonBuscarUbicacion(),
              _selectorUbicacionMapa(),
            ],
          ),
          _seccionFormulario(
            titulo: 'Imagen del evento',
            children: [
              _selectorImagen(),
              Text(
                'Tamaño máximo: 1,5 MB',
                style: TextStyle(
                  color: _cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
              label: Text(
                _guardando
                    ? widget.esEdicion
                          ? 'Actualizando...'
                          : 'Guardando...'
                    : widget.esEdicion
                    ? 'Actualizar evento'
                    : 'Añadir evento',
              ),
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

  Future<void> _buildModalSeleccionarCategoria() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: _cs.primary.withValues(alpha: 0.4), width: 1.5),
      ),

      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _cs.onSurface.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Text(
                      'Seleccione una categoría',
                      style: TextStyle(
                        color: _cs.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: RawScrollbar(
                        controller: _categoriasScrollController,
                        thumbVisibility: true,
                        trackVisibility: false,
                        interactive: true,
                        thickness: 6,
                        radius: const Radius.circular(20),
                        mainAxisMargin: 0,
                        crossAxisMargin: 4,
                        thumbColor: _cs.primary,
                        child: ListView.separated(
                          controller: _categoriasScrollController,
                          padding: const EdgeInsets.only(right: 14),
                          itemCount: _categorias.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final categoria = _categorias[index];

                            final seleccionada =
                                _categoriaSeleccionada == categoria;

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setModalState(() {
                                  _categoriaSeleccionada = categoria;
                                });

                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: seleccionada
                                      ? _cs.primary.withValues(alpha: 0.12)
                                      : _cs.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: seleccionada
                                        ? _cs.primary
                                        : _cs.outline.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      seleccionada
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: seleccionada
                                          ? _cs.primary
                                          : _cs.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        categoria.nombre,
                                        style: TextStyle(
                                          color: seleccionada
                                              ? _cs.primary
                                              : _cs.onSurface,
                                          fontWeight: seleccionada
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cs.primary,
                              foregroundColor: _cs.surface,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Seleccionar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

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
      body: RawScrollbar(
        controller: _formularioScrollController,
        thumbVisibility: true,
        trackVisibility: false,
        interactive: true,
        thickness: 6,
        radius: const Radius.circular(20),
        mainAxisMargin: 24,
        crossAxisMargin: 4,
        thumbColor: _cs.primary,
        child: SingleChildScrollView(
          controller: _formularioScrollController,
          padding: const EdgeInsets.all(24),
          child: _buildFormulario(),
        ),
      ),
    );
  }
}
