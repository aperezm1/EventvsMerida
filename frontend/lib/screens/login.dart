import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _autoLogin = false;
  bool _ocultarPassword = true;

  void _Login() async{
    final url = Uri.parse('http://192.168.101.239:8080/api/usuarios/login');
    final email = emailController.text.trim();
    final password = passwordController.text;

    final respuesta = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (respuesta.statusCode == 200) {
      final datos = jsonDecode(respuesta.body);
      final mensaje = datos.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } else if ((respuesta.statusCode == 404) || (respuesta.statusCode == 400)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Credenciales inválidas')),
      );
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en el servidor ' + respuesta.statusCode.toString())),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.18;
    final logoWidth = size.width * 0.70;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // CABECERA
            Container(
              color: colorScheme.primary,
              width: double.infinity,
              height: headerHeight,
              child: Center(
                child: Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    color: colorScheme.surface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // LOGO
            Container(
              margin: const EdgeInsets.only(top: 24, bottom: 24),
              child: Image.asset(
                'assets/images/logo-eventvs-merida-no-bg.png',
                width: logoWidth,
              ),
            ),

            // CAMPOS DE LOGIN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // CAMPO DE CORREO
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CAMPO DE CONTRASEÑA
                  TextField(
                    controller: passwordController,
                    obscureText: _ocultarPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _ocultarPassword = !_ocultarPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CHECKBOX DE INICIO DE SESIÓN AUTOMÁTICO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _autoLogin,
                        activeColor: colorScheme.primary,
                        onChanged: (value) {
                          setState(() {
                            _autoLogin = value ?? false;
                          });
                        },
                      ),
                      Flexible(
                        child: Text(
                          'Inicio de sesión automático',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // BOTÓN DE INICIAR SESIÓN
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _Login,
                      child: Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.surface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ENLACE PARA REGISTRARSE
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/registro');
                    },
                    child: Text(
                      '¿Aún no tienes cuenta? Regístrate',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}