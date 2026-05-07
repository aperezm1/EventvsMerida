import 'package:eventvsmerida/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:linkify/linkify.dart';

import '../core/router/app_routes.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../utils/utils.dart';

// ===========================================================================
// 1. BARRA SUPERIOR
// ===========================================================================

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const CustomAppBar({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    final _cs = Theme.of(context).colorScheme;

    return AppBar(
      centerTitle: true,
      backgroundColor: _cs.surface,
      foregroundColor: _cs.onSurface,
      elevation: 0,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      title: SizedBox(
        height: 40,
        child: Image.asset(
          'assets/images/logo-eventvs-merida-no-bg.png',
          fit: BoxFit.contain,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ===========================================================================
// 2. MODAL DE DETALLE DEL EVENTO
// ===========================================================================

class ModalEvento extends StatefulWidget {
  final List<Evento> eventos;
  final Usuario? usuario;
  final List<Evento> eventosGuardados;
  final ValueChanged<List<Evento>> onEventosGuardadosActualizados;
  final bool mostrarBotonGuardado;
  final bool mostrarFlechasDeslizamiento;

  const ModalEvento({
    super.key,
    required this.eventos,
    required this.usuario,
    required this.eventosGuardados,
    required this.onEventosGuardadosActualizados,
    this.mostrarBotonGuardado = true,
    this.mostrarFlechasDeslizamiento = false,
  });

  @override
  State<ModalEvento> createState() => _ModalEventoState();
}

class _ModalEventoState extends State<ModalEvento> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  late final PageController _pageController;
  int _indiceActual = 0;
  late List<Evento> _eventosGuardados;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  TextTheme get _tt => Theme.of(context).textTheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _eventosGuardados = List.from(widget.eventosGuardados);
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

  Evento get _eventoActual => widget.eventos[_indiceActual];

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  bool _esMismoEvento(Evento a, Evento b) {
    return a.titulo == b.titulo &&
        a.fechaInicio == b.fechaInicio &&
        a.fechaFin == b.fechaFin;
  }

  bool _estaGuardado(Evento evento) {
    return _eventosGuardados.any((e) => _esMismoEvento(e, evento));
  }

  bool _esMismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _esHoraCero(DateTime fecha) => fecha.hour == 0 && fecha.minute == 0;

  String _formatearFecha(DateTime fecha) =>
      DateFormat('dd/MM/yyyy').format(fecha);

  String _formatearHora(DateTime fecha) => DateFormat('HH:mm').format(fecha);

  String _textoFechaHoraDetalle(Evento evento) {
    final esMismoDia = _esMismoDia(evento.fechaInicio, evento.fechaFin);
    final inicioFecha = _formatearFecha(evento.fechaInicio);
    final finFecha = _formatearFecha(evento.fechaFin);
    final inicioHora = _formatearHora(evento.fechaInicio);
    final finHora = _formatearHora(evento.fechaFin);
    final horasIguales = inicioHora == finHora;
    final ambasHorasCero =
        _esHoraCero(evento.fechaInicio) && _esHoraCero(evento.fechaFin);

    if (esMismoDia) {
      if (horasIguales && ambasHorasCero) return 'Fecha: $inicioFecha';
      if (horasIguales) return 'Fecha: $inicioFecha\nHora: $inicioHora';
      return 'Fecha: $inicioFecha\nHora: $inicioHora - $finHora';
    }
    if (horasIguales && ambasHorasCero)
      return 'Desde: $inicioFecha\nHasta: $finFecha';
    return 'Desde: $inicioFecha $inicioHora\nHasta: $finFecha $finHora';
  }

  void _irAlSiguienteEvento() {
    if (_indiceActual >= widget.eventos.length - 1) return;

    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _irAlEventoAnterior() {
    if (_indiceActual <= 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _abrirEnGoogleMaps(String direccion) async {
    final limpia = direccion.trim();
    final query = Uri.encodeComponent(limpia);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps')),
      );
    }
  }

  Future<void> _compartirEvento(Evento evento) async {
    final texto =
        '''
    ${evento.titulo}
    
    ${evento.localizacion}
    
    Fecha: ${_textoFechaHoraDetalle(evento)}
    
    ${evento.descripcion}
    ''';

    await Share.share(texto, subject: evento.titulo);
  }

  Future<void> _gestionarGuardado() async {
    final usuario = widget.usuario;
    final evento = _eventoActual;

    if (usuario == null) {
      _mostrarModalNoLogeado();
      return;
    }

    final yaGuardado = _estaGuardado(evento);

    final respuesta = yaGuardado
        ? await ApiService.eliminarEventoUsuario(
            usuario.email,
            evento.titulo,
            evento.fechaInicio,
            evento.fechaFin,
          )
        : await ApiService.guardarEventoUsuario(
            usuario.email,
            evento.titulo,
            evento.fechaInicio,
            evento.fechaFin,
          );

    if (!mounted) return;

    if (respuesta.exito) {
      setState(() {
        if (yaGuardado) {
          _eventosGuardados.removeWhere((e) => _esMismoEvento(e, evento));
        } else {
          _eventosGuardados.add(evento);
        }
      });

      widget.onEventosGuardadosActualizados(_eventosGuardados);
    }

    _mostrarSnackBarResultado(
      mensaje: respuesta.mensaje,
      guardado: respuesta.exito ? !yaGuardado : yaGuardado,
    );
  }

  Future<void> _abrirUrl(String urlTexto) async {
    final urlLimpia = urlTexto.trim();

    if (urlLimpia.isEmpty) return;

    final urlConEsquema =
        urlLimpia.startsWith('http://') || urlLimpia.startsWith('https://')
        ? urlLimpia
        : 'https://$urlLimpia';

    final uri = Uri.tryParse(urlConEsquema);

    if (uri == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El enlace no es válido')));
      return;
    }

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  // ===========================================================================
  // MENSAJES
  // ===========================================================================

  void _mostrarSnackBarResultado({
    required String mensaje,
    required bool guardado,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              guardado ? Icons.check : Icons.delete,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(mensaje, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: guardado ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===========================================================================
  // MODALES
  // ===========================================================================

  void _mostrarModalNoLogeado() {
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
                backgroundColor: _cs.surface.withValues(alpha: 0.98),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: _cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Inicia sesión o regístrate',
                            style: _tt.titleMedium?.copyWith(
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
                      style: _tt.bodyMedium,
                    ),
                  ],
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final router = GoRouter.of(context);

                            Navigator.of(ctx).pop();
                            Navigator.of(context).pop();

                            router.push(AppRoutes.registro);
                          },
                          child: Text(
                            'Registrarse',
                            style: TextStyle(color: _cs.surface),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final router = GoRouter.of(context);

                            Navigator.of(ctx).pop();
                            Navigator.of(context).pop();

                            router.push(AppRoutes.login);
                          },
                          child: Text(
                            'Iniciar sesión',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: _cs.surface),
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

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _buildContenidoEvento(Evento evento) {
    final estaGuardado = _estaGuardado(evento);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  evento.titulo,
                  style: _tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _compartirEvento(evento),
                tooltip: 'Compartir evento',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Cerrar',
              ),
            ],
          ),
        ),
        if (widget.eventos.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_indiceActual + 1} de ${widget.eventos.length} eventos en esta ubicación',
              style: _tt.bodySmall?.copyWith(
                color: _cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 320,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 340,
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/images/icono.gif',
                          image: evento.foto,
                          fit: BoxFit.contain,
                          placeholderFit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => _abrirEnGoogleMaps(evento.localizacion),
                  icon: const Icon(Icons.place_outlined, size: 18),
                  label: Text(
                    evento.localizacion,
                    style: _tt.bodyMedium?.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_note, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _textoFechaHoraDetalle(evento),
                        style: _tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Descripción',
                  style: _tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Linkify(
                  text: evento.descripcion,
                  style: _tt.bodyMedium,
                  linkStyle: _tt.bodyMedium?.copyWith(
                    color: _cs.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                  onOpen: (link) => _abrirUrl(link.url),
                  options: const LinkifyOptions(
                    humanize: false,
                    removeWww: false,
                  ),
                  linkifiers: const [UrlLinkifier()],
                ),
              ],
            ),
          ),
        ),
        if (widget.mostrarBotonGuardado)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _gestionarGuardado,
                    icon: Icon(
                      estaGuardado
                          ? Icons.bookmark
                          : Icons.bookmark_border_outlined,
                      color: _cs.surface,
                    ),
                    label: Text(
                      estaGuardado ? 'Evento guardado' : 'Guardar evento',
                      style: _tt.bodyMedium?.copyWith(color: _cs.surface),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Stack(
        children: [
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
                  color: _cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 12,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: widget.eventos.length,
                        onPageChanged: (index) {
                          setState(() {
                            _indiceActual = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return _buildContenidoEvento(widget.eventos[index]);
                        },
                      ),
                      if (widget.mostrarFlechasDeslizamiento &&
                          widget.eventos.length > 1 &&
                          _indiceActual < widget.eventos.length - 1)
                        Positioned(
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IconButton(
                              onPressed: _irAlSiguienteEvento,
                              icon: Icon(
                                Icons.chevron_right,
                                color: _cs.surface,
                                size: 32,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: _cs.primary.withAlpha(90),
                              ),
                            ),
                          ),
                        ),
                      if (widget.mostrarFlechasDeslizamiento &&
                          widget.eventos.length > 1 &&
                          _indiceActual > 0)
                        Positioned(
                          left: 8,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IconButton(
                              onPressed: _irAlEventoAnterior,
                              icon: Icon(
                                Icons.chevron_left,
                                color: _cs.surface,
                                size: 32,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: _cs.primary.withAlpha(90),
                              ),
                            ),
                          ),
                        ),
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

class Tutorial {
  static final pasosTutorial = <TargetFocus>[];
  static late TutorialCoachMark _tutorial;
  static bool tutorialInicializado = false;
  static final GlobalKey keyNavMapa = GlobalKey();
  static final GlobalKey keyNavCalendario = GlobalKey();
  static final GlobalKey keyNavPerfil = GlobalKey();
  static final ValueNotifier<bool> navPasoActivo = ValueNotifier(false);
  static int numPantalla = 1;

  static TutorialCoachMark get tutorial => _tutorial;

  static void set tutorial(TutorialCoachMark value) {
    _tutorial = value;
    tutorialInicializado = true;
  }

  static void mostrarTutorial(BuildContext context) {
    _tutorial.show(context: context, rootOverlay: true);
  }

  static TutorialCoachMark crearTutorial({
    required BuildContext context,
    required List<TargetFocus> pasosTutorial,
    required Color color,
  }) {
    return TutorialCoachMark(
      targets: pasosTutorial,
      colorShadow: color,
      textSkip: "SALTAR TUTORIAL",
      paddingFocus: 15,
      opacityShadow: 0.5,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onSkip: () {
        SharedPreferencesService.finalizarTurorial();
        return true;
      },
    );
  }

  static void resetearTutorial() {
    tutorialInicializado = false;
    pasosTutorial.clear();
    navPasoActivo.value = false;
    numPantalla = 1;
  }

  static TargetFocus crearPaso({
    required GlobalKey key,
    required BuildContext context,
    required String titulo,
    required String descripcion,
    required IconData icon,
    required bool siguiente,
    ShapeLightFocus? forma,
    ContentAlign alineamientoTarjeta = ContentAlign.bottom,
    required VoidCallback? onNext,
  }) {
    return TargetFocus(
      identify: '${titulo}_${key.hashCode}',
      keyTarget: key,
      alignSkip: Alignment.topLeft,
      shape: forma ?? ShapeLightFocus.Circle,
      enableTargetTab: false,
      contents: [
        TargetContent(
          align: alineamientoTarjeta,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _tutorialCard(
              context: context,
              icon: icon,
              title: titulo,
              message: descripcion,
              buttonText: siguiente ? 'Siguiente' : 'Finalizar tutorial',
              onNext: onNext,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _tutorialCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    String buttonText = 'Siguiente',
    VoidCallback? onNext,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: cs.onPrimary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onNext, child: Text(buttonText)),
          ),
        ],
      ),
    );
  }
}

Future<XFile?> elegirImagen(BuildContext context) async {
  ImagePicker picker = ImagePicker();
  final fuente = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );

  if (fuente == null) return null;

  try {
    final XFile? imagen = await picker.pickImage(
      source: fuente,
      imageQuality: 80,
    );

    if (imagen == null) return null;

    return imagen;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al seleccionar la imagen')),
    );
    return null;
  }
}

typedef CampoTextoBuilder =
    Widget Function(
      String label, {
      required TextEditingController controller,
      TextInputType? keyboardType,
      bool isPassword,
      bool obscureText,
      VoidCallback? onToggle,
      bool readOnly,
      bool isDropdown,
      int? maxLength,
      List<TextInputFormatter>? inputFormatters,
    });

typedef ValidadorCampo = String? Function(String label, String? value);

class CampoTexto {
  static Widget buildCampoTexto(
    String label, {
    required BuildContext context,
    required TextEditingController controller,
    required ValidadorCampo validator,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
    bool readOnly = false,
    bool isDropdown = false,
    bool obligatorio = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        style: TextStyle(color: cs.onSurface),
        validator: (value) => validator(label, value),
        decoration: buildDecoration(
          context: context,
          label: label,
          obligatorio: obligatorio,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: cs.primary.withValues(alpha: 0.6),
                  ),
                  onPressed: onToggle,
                )
              : (isDropdown ? const Icon(Icons.arrow_drop_down) : null),
        ).copyWith(counterText: maxLength != null ? '' : null),
        obscureText: isPassword ? obscureText : false,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
      ),
    );
  }

  static InputDecoration buildDecoration({
    required BuildContext context,
    required String label,
    Widget? suffixIcon,
    bool obligatorio = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.7),
            fontSize: 16,
          ),
          children: obligatorio
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              : [],
        ),
      ),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
    );
  }
}

class CampoObligatorio extends StatelessWidget {
  final String texto;
  final bool obligatorio;
  final TextStyle? style;

  const CampoObligatorio({
    super.key,
    required this.texto,
    this.obligatorio = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RichText(
      text: TextSpan(
        text: texto,
        style:
            style ??
            TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 16),
        children: obligatorio
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : [],
      ),
    );
  }
}

class SelectorFecha {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  static String? mesSeleccionado;

  static const List<String> meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const Map<String, String> mesNumero = {
    'Enero': '01',
    'Febrero': '02',
    'Marzo': '03',
    'Abril': '04',
    'Mayo': '05',
    'Junio': '06',
    'Julio': '07',
    'Agosto': '08',
    'Septiembre': '09',
    'Octubre': '10',
    'Noviembre': '11',
    'Diciembre': '12',
  };

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  static String _mesANumero(String mes) {
    return mesNumero[mes] ?? '01';
  }

  static String? obtenerFechaFormateada(
    TextEditingController diaController,
    TextEditingController anioController,
  ) {
    if (mesSeleccionado == null) {
      return null;
    }

    final dia = int.tryParse(diaController.text.trim());
    final anio = int.tryParse(anioController.text.trim());
    final mes = int.parse(_mesANumero(mesSeleccionado!));

    if (dia == null || anio == null) {
      return null;
    }

    try {
      final fecha = DateTime(anio, mes, dia);
      final fechaValida =
          fecha.day == dia && fecha.month == mes && fecha.year == anio;

      if (!fechaValida || fecha.isAfter(DateTime.now())) {
        return null;
      }

      final diaTxt = dia.toString().padLeft(2, '0');
      final mesTxt = mes.toString().padLeft(2, '0');
      return '$diaTxt/$mesTxt/$anio';
    } catch (_) {
      return null;
    }
  }

  static Widget buildFilaFecha({
    required BuildContext context,
    required TextEditingController diaController,
    required TextEditingController mesController,
    required TextEditingController anioController,
    required ValueChanged<String> onSeleccionarMes,
    required ValidadorCampo validator,
    required bool obligatorio,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: CampoTexto.buildCampoTexto(
            'Día',
            context: context,
            controller: diaController,
            validator: validator,
            keyboardType: TextInputType.number,
            maxLength: 2,
            inputFormatters: [DayRangeTextInputFormatter()],
            obligatorio: obligatorio,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: PopupMenuButton<String>(
            constraints: const BoxConstraints(maxHeight: 200, minWidth: 120),
            onSelected: onSeleccionarMes,
            itemBuilder: (context) {
              return meses.map((mes) {
                return PopupMenuItem<String>(
                  value: mes,
                  child: Text(mes, style: TextStyle(color: cs.onSurface)),
                );
              }).toList();
            },
            child: AbsorbPointer(
              child: CampoTexto.buildCampoTexto(
                'Mes',
                context: context,
                controller: mesController,
                validator: validator,
                readOnly: true,
                isDropdown: true,
                obligatorio: obligatorio,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: CampoTexto.buildCampoTexto(
            'Año',
            context: context,
            controller: anioController,
            validator: validator,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            obligatorio: obligatorio,
          ),
        ),
      ],
    );
  }
}
