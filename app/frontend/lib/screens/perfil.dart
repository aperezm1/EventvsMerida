import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../core/router/app_routes.dart';
import '../core/theme/controlador_tema.dart';
import '../services/shared_preferences_service.dart';
import '../models/usuario.dart';
import '../widgets/componentes_compartidos.dart';

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  Usuario? _usuario;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  bool get _puedeAdministrarEventos {
    final rol = _usuario?.rol.trim().toLowerCase();

    return rol == 'organizador' || rol == 'administrador';
  }

  GlobalKey keyCabecera = GlobalKey();
  GlobalKey keySecciones = GlobalKey();
  GlobalKey keyPreferencias = GlobalKey();
  GlobalKey keyinfoLegal = GlobalKey();
  GlobalKey keyAdmin = GlobalKey();
  bool cargarTutorial = false;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarTutorial();
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

  Future<void> _cargarTutorial() async {
    final tutorialActivo = await SharedPreferencesService.cargarTutorial();

    if (!mounted) return;

    setState(() {
      cargarTutorial = tutorialActivo;
    });

    if (tutorialActivo) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        _comprobarInicializacionTutorial();
      });
    }
  }

  bool _targetEstaListo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return false;

    final renderObject = ctx.findRenderObject();
    return renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize;
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  void _cambiarTema(bool activado) {
    themeController.value = activado ? ThemeMode.dark : ThemeMode.light;
  }

  void _comprobarInicializacionTutorial() {
    if (!mounted) return;
    if (Tutorial.numPantalla != 4) return;
    if (Tutorial.tutorialInicializado) return;
    if (!_targetEstaListo(keyCabecera) || !_targetEstaListo(keySecciones))
      return;

    Tutorial.tutorialInicializado = true;
    _configurarTutorial();
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        titulo,
        style: TextStyle(color: _cs.primary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildItem(
    IconData icono,
    String titulo, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icono),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      onTap: onTap,
    );
  }

  Widget _buildCabeceraNoLogueado() {
    return Column(
      key: keyCabecera,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Regístrate o inicia sesión',
          style: TextStyle(
            color: _cs.surface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _cs.surface),
                foregroundColor: _cs.surface,
              ),
              onPressed: () => context.push(AppRoutes.registro),
              child: const Text('Registrarse'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cs.surface,
                foregroundColor: _cs.onSurface,
              ),
              onPressed: () => context.push(AppRoutes.login),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCabeceraLogueado() {
    return Column(
      key: keyCabecera,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _cs.surface,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Container(
              color: _cs.surface.withValues(alpha: 0.9),
              child: _usuario?.fotoUrl != null && _usuario!.fotoUrl!.isNotEmpty
                  ? FadeInImage.assetNetwork(
                placeholder: 'assets/images/icono.gif',
                image: _usuario!.fotoUrl!,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholderFit: BoxFit.contain,
              )
                  : Icon(
                Icons.person,
                color: _cs.primary,
                size: 34,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_usuario!.nombre} ${_usuario!.apellidos}',
          style: TextStyle(
            color: _cs.surface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildCabecera() {
    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        color: _cs.primary,
        child: _usuario == null
            ? _buildCabeceraNoLogueado()
            : _buildCabeceraLogueado(),
      ),
    );
  }

  Widget _buildModoOscuro() {
    return _buildItem(
      Icons.dark_mode,
      'Modo Oscuro',
      trailing: Switch(
        value: Theme.of(context).brightness == Brightness.dark,
        activeThumbColor: _cs.secondary,
        onChanged: _cambiarTema,
      ),
    );
  }

  Widget _buildPreferencias() {
    final isRegistrado = _usuario != null;

    return Column(
      key: keyPreferencias,
      children: [
        if (isRegistrado) ...[
          _buildItem(
            Icons.account_circle,
            'Cuenta',
            onTap: () => context.push(AppRoutes.cuenta),
          ),
          _buildItem(
            Icons.bookmark_border,
            'Eventos guardados',
            onTap: () => context.push(AppRoutes.eventosGuardados),
          ),
          //_buildItem(Icons.notifications, 'Preferencias de notificaciones'),
        ],
        _buildModoOscuro(),
        if (!cargarTutorial)
          _buildItem(
            Icons.help_outline,
            'Volver a hacer tutorial',
            onTap: () async {
              await SharedPreferencesService.resetearTutorial();
              Tutorial.resetearTutorial();
              context.go(AppRoutes.eventos);
            },
          ),
      ],
    );
  }

  Widget _buildAdministracion() {
    return Column(
      key: keyAdmin,
      children: [
        _buildItem(
          Icons.event_available,
          'Administrar eventos',
          onTap: () => context.push(AppRoutes.administrarEventos),
        ),
      ],
    );
  }

  Widget _buildLegal() {
    return Column(
      key: keyinfoLegal,
      children: [
        _buildItem(
          Icons.file_copy,
          'Términos y servicios',
          onTap: () => context.push(AppRoutes.terminos),
        ),
        _buildItem(
          Icons.privacy_tip,
          'Política de privacidad',
          onTap: () => context.push(AppRoutes.privacidad),
        ),
      ],
    );
  }

  // ===========================================================================
  // TUTORIAL
  // ===========================================================================

  void _configurarTutorial() {
    Tutorial.pasosTutorial.clear();
    cargarPasosTutorial();
    Tutorial.tutorial = Tutorial.crearTutorial(
      context: context,
      pasosTutorial: Tutorial.pasosTutorial,
      color: Theme.of(context).colorScheme.primary,
    );
    Tutorial.tutorial.show(context: context);
  }

  Future<void> finalizarTutorial() async {
    Tutorial.tutorialInicializado = false;
    Tutorial.tutorial.finish();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Tutorial.numPantalla = 5;
    await SharedPreferencesService.finalizarTurorial();

    if (!mounted) return;
    context.go(AppRoutes.eventos);
    Mensaje.mostrarSnackBar(context: context, mensaje: "¡Has completado el tutorial!", icon: Icons.help_outline, color: Colors.green);
  }

  void cargarPasosTutorial() {
    if (_usuario == null) {
      Tutorial.pasosTutorial.add(
        Tutorial.crearPaso(
          context: context,
          key: keyCabecera,
          titulo: 'Registrarse o iniciar sesión',
          descripcion: 'En esta sección puedes registrarte para crear una cuenta o iniciar sesión si ya tienes una. Al hacerlo, podrás acceder a funciones personalizadas como guardar eventos favoritos.',
          icon: Icons.calendar_month,
          siguiente: true,
          onNext: () => Tutorial.tutorial.next(),
          forma: ShapeLightFocus.RRect,
        ),
      );

      Tutorial.pasosTutorial.add(
        Tutorial.crearPaso(
          context: context,
          key: keySecciones,
          titulo: 'Preferencias e información legal',
          descripcion: 'Aquí puedes configurar tus preferencias, eventos guardados, o la política de privacidad entre otros.',
          icon: Icons.list_alt,
          siguiente: false,
          onNext: () => finalizarTutorial(),
          forma: ShapeLightFocus.RRect,
        ),
      );
    } else {
      Tutorial.pasosTutorial.add(
        Tutorial.crearPaso(
          context: context,
          key: keyPreferencias,
          titulo: 'Preferencias',
          descripcion: 'En esta sección puedes configurar tus preferencias, como tus datos personales o los eventos guardados.',
          icon: Icons.calendar_month,
          siguiente: true,
          onNext: () => Tutorial.tutorial.next(),
          forma: ShapeLightFocus.RRect,
        ),
      );

      if (_usuario?.rol.toLowerCase() == 'organizador' || _usuario?.rol.toLowerCase() == 'administrador') {
        Tutorial.pasosTutorial.add(
          Tutorial.crearPaso(
            context: context,
            key: keyAdmin,
            titulo: 'Administración',
            descripcion: 'Aquí puedes gestionar todos los datos de tus eventos, tanto crear nuevos, como editar o eliminar los existentes.',
            icon: Icons.admin_panel_settings,
            siguiente: true,
            onNext: () => Tutorial.tutorial.next(),
            forma: ShapeLightFocus.RRect,
          ),
        );
      }

      Tutorial.pasosTutorial.add(
        Tutorial.crearPaso(
          alineamientoTarjeta: ContentAlign.top,
          context: context,
          key: keyinfoLegal,
          titulo: 'Información legal',
          descripcion: 'Aquí puedes consultar los términos y condiciones así como la política de privacidad.',
          icon: Icons.calendar_month,
          siguiente: false,
          onNext: () => finalizarTutorial(),
          forma: ShapeLightFocus.RRect,
        ),
      );
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildCabecera(),
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                      child: Column(
                        key: keySecciones,
                        children: [
                          _buildSeccionTitulo('PREFERENCIAS'),
                          _buildPreferencias(),
                          if (_puedeAdministrarEventos) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 16.0,
                              ),
                              child: Divider(color: _cs.primary, thickness: 2),
                            ),
                            _buildSeccionTitulo('ADMINISTRACIÓN'),
                            _buildAdministracion(),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 16.0,
                            ),
                            child: Divider(color: _cs.primary, thickness: 2),
                          ),
                          _buildSeccionTitulo('INFORMACIÓN LEGAL'),
                          _buildLegal(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SafeArea(
                      top: false,
                      bottom: true,
                      left: false,
                      right: false,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          right: 24.0,
                          bottom: 8.0,
                          top: 8.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Image.asset(
                              'assets/images/logo-eventvs-merida-no-bg.png',
                              height: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Versión 1.0.0',
                              style: TextStyle(
                                color: _cs.onSurface,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}