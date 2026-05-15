import 'package:eventvsmerida/services/api_service.dart';
import 'package:eventvsmerida/utils/fecha_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../models/usuario.dart';
import '../services/shared_preferences_service.dart';
import '../widgets/componentes_compartidos.dart';

/// Pantalla de cuenta de usuario, donde se muestran los datos del usuario,
/// configurar preferencias, editar los datos o cerrar sesión.
///
/// @author: Eva Retamar
/// @author: Adrián Pérez
/// @author: David Muñoz
class Cuenta extends StatefulWidget {
  const Cuenta({super.key});

  @override
  State<Cuenta> createState() => _CuentaState();
}

class _CuentaState extends State<Cuenta> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  Usuario? _usuario;
  FechaUtils fu = FechaUtils();

  ColorScheme get _cs => Theme.of(context).colorScheme;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repetirPasswordController = TextEditingController();
  final TextEditingController _diaController = TextEditingController();
  final TextEditingController _mesController = TextEditingController();
  final TextEditingController _anioController = TextEditingController();

  final _formDatosKey = GlobalKey<FormState>();
  final _formContraseniaKey = GlobalKey<FormState>();

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _repetirPasswordController.dispose();
    _telefonoController.dispose();
    _diaController.dispose();
    _mesController.dispose();
    _anioController.dispose();
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

      if (usuario != null) {
        _rellenarControllersDesdeUsuario(usuario);
      }
    });
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  Future<void> _editarImagenPerfil() async {
    final imagenSeleccionada = await elegirImagen(context);

    if (imagenSeleccionada == null) return;
    if (_usuario == null) return;

    final respuesta = await ApiService.editarUsuario(
      idUsuario: _usuario!.id,
      datosUsuario: {},
      imagen: imagenSeleccionada,
    );

    if (!mounted) return;

    if (respuesta.exito && respuesta.datos != null) {
      setState(() {
        _usuario = respuesta.datos;
      });

      await SharedPreferencesService.iniciarSesion(
        usuario: respuesta.datos!,
        autoLogin: await SharedPreferencesService.getAutoLogin(),
      );

      if (!mounted) return;
      Mensaje.mostrarSnackBar(context: context, mensaje: 'Imagen actualizada correctamente', icon: Icons.check, color: Colors.green);
    } else {
      Mensaje.mostrarSnackBar(context: context, mensaje: respuesta.mensaje, icon: Icons.close, color: _cs.error);
    }
  }

  InputDecoration _decorationModal(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _cs.primary),
      labelStyle: TextStyle(color: _cs.onSurface.withValues(alpha: 0.7)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cs.onSurface.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cs.error, width: 2),
      ),
    );
  }

  String? _validarCampo(String label, String? value) {
    final texto = (value ?? '').trim();

    if (label == 'Correo') {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(texto)) {
        return 'Introduce un email válido';
      }
    }

    if (label == 'Teléfono') {
      final phoneRegex = RegExp(r'^[679]\d{8}$');
      if (!phoneRegex.hasMatch(texto)) {
        return 'Debe tener 9 dígitos y empezar por 6, 7 o 9';
      }
    }

    if (label == 'Contraseña') {
      final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
      if (!passwordRegex.hasMatch(texto)) {
        return 'Debe tener 8 carácteres, mayúscula, minúscula y número';
      }
    }

    if (label == 'Confirmar contraseña' && texto != _passwordController.text) {
      return 'Las contraseñas deben coincidir';
    }

    return null;
  }

  void seleccionarMes(String mes) {
    setState(() {
      SelectorFecha.mesSeleccionado = mes;
      _mesController.text = mes;
    });
  }

  void _limpiarCamposContrasenia() {
    _passwordController.clear();
    _repetirPasswordController.clear();
  }

  void _rellenarControllersDesdeUsuario(Usuario usuario) {
    _nombreController.text = usuario.nombre;
    _apellidosController.text = usuario.apellidos;
    _correoController.text = usuario.email;
    _telefonoController.text = usuario.telefono;

    final fecha = usuario.fechaNacimiento;

    _diaController.text = fecha.day.toString().padLeft(2, '0');
    _mesController.text = SelectorFecha.meses[fecha.month - 1];
    SelectorFecha.mesSeleccionado = _mesController.text;
    _anioController.text = fecha.year.toString();
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _infoTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cs.secondary.withValues(alpha: 0.15),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: _cs.primary, size: 28),
        title: Text(
          label,
          style: TextStyle(
            color: _cs.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(color: _cs.onSurface, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    if (_usuario == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        children: [
          _infoTile(
            label: 'Nombre',
            value: _usuario!.nombre,
            icon: Icons.badge,
          ),
          _infoTile(
            label: 'Apellidos',
            value: _usuario!.apellidos,
            icon: Icons.badge,
          ),
          _infoTile(
            label: 'Fecha de nacimiento',
            value: fu.formatearFechaNacimiento(_usuario!.fechaNacimiento),
            icon: Icons.cake,
          ),
          _infoTile(
            label: 'Correo electrónico',
            value: _usuario!.email,
            icon: Icons.email,
          ),
          _infoTile(
            label: 'Teléfono',
            value: _usuario!.telefono,
            icon: Icons.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        color: _cs.primary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: _cs.surface),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        context.pop();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ),
                Center(
                  child: Text(
                    'Cuenta',
                    style: TextStyle(
                      color: _cs.surface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: _editarImagenPerfil,
              child: SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _cs.surface,
                            width: 0.5,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: _cs.surface.withValues(alpha: 0.9),
                          radius: 45,
                          child: _usuario?.fotoUrl != null &&
                              _usuario!.fotoUrl!.isNotEmpty
                              ? ClipOval(
                            child: FadeInImage.assetNetwork(
                              placeholder: 'assets/images/icono.gif',
                              image: _usuario!.fotoUrl!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              placeholderFit: BoxFit.contain,
                            ),
                          )
                              : Icon(
                            Icons.person,
                            color: _cs.primary,
                            size: 34,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _cs.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _cs.primary,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: _cs.primary,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBotones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        children: [
          if (_usuario != null) ...[
            // Botón superior: Cambiar contraseña
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.lock_reset, color: _cs.surface),
                label: Text(
                  'Cambiar contraseña',
                  style: TextStyle(color: _cs.surface),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cs.primary,
                  foregroundColor: _cs.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  _limpiarCamposContrasenia();
                  _buildModalEditarContrasenia();
                },
              ),
            ),

            const SizedBox(height: 12),

            // Fila inferior: Editar datos + Cerrar sesión
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit, color: _cs.surface),
                    label: Text(
                      'Editar datos',
                      style: TextStyle(color: _cs.surface),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cs.primary,
                      foregroundColor: _cs.onPrimary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      _buildModalEditarDatos();
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cs.error,
                      foregroundColor: _cs.onError,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () async {
                      final confirmar = await SalidaApp.mostrarModalConfirmacion(
                        context: context,
                        titulo: 'Cerrar sesión',
                        mensaje: '¿Seguro que quieres cerrar sesión?',
                        icono: Icons.logout,
                        textoConfirmar: 'Cerrar sesión',
                        colorConfirmar: _cs.error,
                      );

                      if (!confirmar) return;

                      await ApiService.cerrarSesionRemota();
                      await SharedPreferencesService.cerrarSesion();
                      if (!mounted) return;
                      context.go(AppRoutes.eventos);
                      Mensaje.mostrarSnackBar(
                        context: context,
                        mensaje: "Has cerrado sesión...",
                        icon: Icons.person,
                        color: _cs.error,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _buildBodyEditar(String fechaNacimiento, {bool incluirPassword = false}) {
   return {
      'nombre': _nombreController.text.trim().isEmpty ? null : _nombreController.text.trim(),
      'apellidos': _apellidosController.text.trim().isEmpty ? null : _apellidosController.text.trim(),
      'fechaNacimiento': fechaNacimiento.isEmpty ? null : fechaNacimiento,
      'email': _correoController.text.trim().isEmpty ? null : _correoController.text.trim(),
      'telefono': _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
      'password': incluirPassword ? _passwordController.text.trim() : null,
      'fotoPath': null,
    };
  }

  Future<void> _buildModalEditarDatos() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: _cs.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formDatosKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    'Editar datos',
                    style: TextStyle(
                      color: _cs.surface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _nombreController,
                    decoration: _decorationModal('Nombre', Icons.person),
                    validator: (value) => _validarCampo('Nombre', value),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _apellidosController,
                    decoration: _decorationModal('Apellidos', Icons.badge),
                    validator: (value) => _validarCampo('Apellidos', value),
                  ),

                  const SizedBox(height: 12),

                  SelectorFecha.buildFilaFecha(context: context, diaController: _diaController, mesController: _mesController, anioController: _anioController, onSeleccionarMes: seleccionarMes, validator: _validarCampo, obligatorio: false),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decorationModal(
                      'Correo electrónico',
                      Icons.email,
                    ),
                    validator: (value) => _validarCampo('Correo', value),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: _decorationModal('Teléfono', Icons.phone),
                    validator: (value) => _validarCampo('Teléfono', value),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                              if (_usuario != null) {
                                _rellenarControllersDesdeUsuario(_usuario!);
                              }

                              Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _cs.primary,
                            side: BorderSide(color: _cs.primary),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_formDatosKey.currentState!.validate()) return;

                            final fechaNacimiento = SelectorFecha.obtenerFechaFormateada(
                              _diaController,
                              _anioController,
                            );

                            if (fechaNacimiento == null) {
                              Mensaje.mostrarSnackBar(context: context, mensaje: 'Fecha inválida o futura', icon: Icons.close, color: _cs.error);
                              return;
                            }

                            final respuesta = await ApiService.editarUsuario(
                              idUsuario: _usuario!.id,
                              datosUsuario: _buildBodyEditar(fechaNacimiento),
                            );

                            if (!mounted) return;

                            Navigator.pop(context);

                            if (respuesta.exito && respuesta.datos != null) {
                              setState(() {
                                _usuario = respuesta.datos;
                              });

                              await SharedPreferencesService.iniciarSesion(
                                usuario: respuesta.datos!,
                                autoLogin: await SharedPreferencesService.getAutoLogin(),
                              );

                              if (!mounted) return;
                              Mensaje.mostrarSnackBar(context: context, mensaje: 'Datos actualizados correctamente', icon: Icons.check, color: Colors.green);
                            } else {
                              Mensaje.mostrarSnackBar(context: context, mensaje: respuesta.mensaje, icon: Icons.close, color: _cs.error);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cs.primary,
                            foregroundColor: _cs.onPrimary,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text('Editar datos', style: TextStyle(color: _cs.surface)),
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
    _rellenarControllersDesdeUsuario(_usuario!);
  }

  Future<void> _buildModalEditarContrasenia() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: _cs.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formContraseniaKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    'Cambiar contraseña',
                    style: TextStyle(
                      color: _cs.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: _decorationModal('Contraseña nueva', Icons.key),
                    validator: (value) => _validarCampo('Contraseña', value),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _repetirPasswordController,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: _decorationModal(
                      'Confirmar contraseña',
                      Icons.key,
                    ),
                    validator: (value) => _validarCampo('Confirmar contraseña', value),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _cs.primary,
                            side: BorderSide(color: _cs.primary),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_formContraseniaKey.currentState!.validate()) return;

                            final fechaNacimiento = SelectorFecha.obtenerFechaFormateada(
                              _diaController,
                              _anioController,
                            );

                            final respuesta = await ApiService.editarUsuario(
                              idUsuario: _usuario!.id,
                              datosUsuario: _buildBodyEditar(fechaNacimiento!, incluirPassword: true),
                            );

                            if (!mounted) return;

                            Navigator.pop(context);

                            if (respuesta.exito && respuesta.datos != null) {
                              setState(() {
                                _usuario = respuesta.datos;
                              });

                              await SharedPreferencesService.iniciarSesion(
                                usuario: respuesta.datos!,
                                autoLogin: await SharedPreferencesService.getAutoLogin(),
                              );

                              if (!mounted) return;
                              Mensaje.mostrarSnackBar(context: context, mensaje: 'Contraseña actualizada correctamente', icon: Icons.check, color: Colors.green);
                            } else {
                              Mensaje.mostrarSnackBar(context: context, mensaje: respuesta.mensaje, icon: Icons.close, color: _cs.error);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cs.primary,
                            foregroundColor: _cs.onPrimary,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            'Cambiar contraseña',
                            maxLines: 1,
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
    _limpiarCamposContrasenia();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cs.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CABECERA
          _buildHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // DATOS DEL USUARIO
                  _buildUserInfo(),

                  // BOTONES
                  _buildBotones(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

