import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';
import '../widgets/componentes_compartidos.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _autoLogin = false;
  bool _ocultarPassword = true;
  final _formKey = GlobalKey<FormState>();

  ColorScheme get _cs =>
      Theme
          .of(context)
          .colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  InputDecoration _buildDecoration({
    required String labelText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: _cs.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: _cs.primary,
          width: 2,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }

  String? _validarEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Introduce tu correo';
    }

    final emailRegex = RegExp(
      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Introduce un correo válido';
    }

    return null;
  }

  String? _validarCamposVacios() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty && password.isEmpty) {
      return 'Introduce tu correo y tu contraseña';
    }

    if (email.isEmpty) {
      return 'Introduce tu correo';
    }

    if (password.isEmpty) {
      return 'Introduce tu contraseña';
    }

    return null;
  }

  Future<void> _iniciarSesion() async {
    final mensajeError = _validarCamposVacios();

    if (mensajeError != null) {
      Mensaje.mostrarSnackBar(context: context,
          mensaje: mensajeError,
          icon: Icons.person,
          color: _cs.error);
      return;
    }

    final respuesta = await ApiService.iniciarSesion(
      _emailController.text.trim(),
      _passwordController.text,
      rememberMe: _autoLogin,
    );

    if (!mounted) return;

    if (!respuesta.exito) {
      Mensaje.mostrarSnackBar(context: context, mensaje: respuesta.mensaje, icon: Icons.person, color: _cs.error);
      return;
    }

    final usuario = respuesta.datos!;

    Mensaje.mostrarSnackBar(context: context,
        mensaje: "¡Has iniciado sesión correctamente!",
        icon: Icons.person,
        color: Colors.green);
    await SharedPreferencesService.iniciarSesion(
      usuario: usuario,
      autoLogin: _autoLogin,
    );

    if (!mounted) return;

    context.go(AppRoutes.eventos);
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _buildHeader() {
    final puedeVolver = context.canPop();

    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 35.0, horizontal: 16.0),
        color: _cs.primary,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: puedeVolver
                  ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: _cs.surface,
                ),
                onPressed: () {
                  context.pop();
                },
              )
                  : const SizedBox.shrink(),
            ),
            Text(
              'Iniciar sesión',
              style: TextStyle(
                color: _cs.surface,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(double logoWidth) {
    return Image.asset(
      'assets/images/logo-eventvs-merida-no-bg.png',
      width: logoWidth,
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: _buildDecoration(
        labelText: 'Correo',
      ),
      onSubmitted: (_) => _iniciarSesion(),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _ocultarPassword,
      textInputAction: TextInputAction.done,
      decoration: _buildDecoration(
        labelText: 'Contraseña',
        suffixIcon: IconButton(
          icon: Icon(
            _ocultarPassword ? Icons.visibility_off : Icons.visibility,
            color: _cs.primary,
          ),
          onPressed: () {
            setState(() {
              _ocultarPassword = !_ocultarPassword;
            });
          },
        ),
      ),
      onSubmitted: (_) => _iniciarSesion(),
    );
  }

  Widget _buildAutoLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _autoLogin,
          activeColor: _cs.primary,
          checkColor: _cs.surface,
          onChanged: (value) {
            setState(() {
              _autoLogin = value ?? false;
            });
          },
        ),
        Flexible(
          child: Text(
            'Inicio de sesión automático',
            style: TextStyle(color: _cs.onSurface),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _cs.primary,
          foregroundColor: _cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _iniciarSesion,
        child: Text(
          'Iniciar sesión',
          style: TextStyle(
            fontSize: 16,
            color: _cs.surface,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿Aún no tienes cuenta? ',
              style: TextStyle(color: _cs.onSurface),
            ),
            GestureDetector(
              onTap: () {
                context.push(AppRoutes.registro);
              },
              child: Text(
                'Regístrate',
                style: TextStyle(
                  color: _cs.onSurface,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                _buildModalRecuperarContrasenia();
              },
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: _cs.onSurface,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.5,
                ),
              ),
            ),
          ],
        ),
      ]
    );
  }

  Future<void> _buildModalRecuperarContrasenia() async {
    bool enviandoCorreo = false;

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
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
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
                        'Recuperar contraseña',
                        style: TextStyle(
                          color: _cs.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _buildDecoration(
                          labelText: 'Correo electrónico',
                        ),
                        validator: _validarEmail,
                      ),

                      const SizedBox(height: 20),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: enviandoCorreo
                                  ? null
                                  : () {
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
                              onPressed: enviandoCorreo
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate()) return;

                                      setModalState(() {
                                        enviandoCorreo = true;
                                      });

                                      final respuesta = await ApiService.recuperarPassword(
                                        _emailController.text.trim(),
                                      );

                                      if (!mounted) return;

                                      setModalState(() {
                                        enviandoCorreo = false;
                                      });

                                      Navigator.pop(context);

                                      _mostrarModalCorreoEnviado();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cs.primary,
                                foregroundColor: _cs.onPrimary,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: Text(
                                enviandoCorreo ? 'Enviando...' : 'Enviar correo',
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
      },
    );
  }

  Future<void> _mostrarModalCorreoEnviado() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.mark_email_read, color: _cs.primary),
              const SizedBox(width: 8),
              const Text('Correo enviado'),
            ],
          ),
          content: const Text(
            'Si la dirección de correo electrónico está registrada, te hemos enviado un mensaje con las instrucciones para restablecer tu contraseña.\n\n'
                'Por favor, revisa tu bandeja de entrada y, si no lo encuentras, comprueba la carpeta de correo no deseado o SPAM.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;
    final logoWidth = size.width * 0.70;

    return Scaffold(
      backgroundColor: _cs.surface,
      body: Column(
        children: [
          // CABECERA
          _buildHeader(),

          // CUERPO PRINCIPAL
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: _cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // LOGO
                      _buildLogo(logoWidth),
                      const SizedBox(height: 50),

                      // CAMPOS DE LOGIN
                      Column(
                        children: [
                          _buildEmailField(),
                          const SizedBox(height: 16),
                          _buildPasswordField(),
                          const SizedBox(height: 16),

                          // CHECKBOX DE INICIO DE SESIÓN AUTOMÁTICO
                          _buildAutoLogin(),
                          const SizedBox(height: 16),

                          // BOTÓN DE INICIAR SESIÓN
                          _buildLoginButton(),
                          const SizedBox(height: 16),

                          // ENLACE PARA REGISTRARSE
                          _buildRegisterLink(),
                        ],
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