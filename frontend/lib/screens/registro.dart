import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final _formKey = GlobalKey<FormState>();

  bool _aceptaTerminos = false;
  bool _oscurecerPassword = true;
  bool _oscurecerRepetirPassword = true;
  String? _mesSeleccionado;

  final List<String> _meses = [
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

  String mesANumero(String mes) {
    const meses = {
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
    return meses[mes] ?? '01';
  }

  final _mesController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repetirPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _diaController = TextEditingController();
  final _anioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: colorScheme.primary,
            alignment: Alignment.center,
            child: Text(
              'Crear cuenta',
              style: TextStyle(
                fontSize: 28,
                fontWeight: .bold,
                color: colorScheme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const .vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context,
                              "Nombre",
                              controller: _nombreController,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Espacio horizontal entre los dos cuadros
                          Expanded(
                            child: _buildTextField(
                              context,
                              "Apellido",
                              controller: _apellidoController,
                            ),
                          ),
                        ],
                      ),
                      _buildTextField(
                        context,
                        "Correo",
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        context,
                        "Contraseña",
                        controller: _passwordController,
                        isPassword: true,
                        isObscured: _oscurecerPassword,
                        onToggle: () {
                          setState(() {
                            _oscurecerPassword = !_oscurecerPassword;
                          });
                        },
                      ),
                      _buildTextField(
                        context,
                        "Repetir contraseña",
                        controller: _repetirPasswordController,
                        isPassword: true,
                        isObscured: _oscurecerRepetirPassword,
                        onToggle: () {
                          setState(() {
                            _oscurecerRepetirPassword = !_oscurecerRepetirPassword;
                          });
                        },
                      ),
                      _buildTextField(
                        context,
                        "Número de teléfono",
                        controller: _telefonoController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context,
                              "Día",
                              controller: _diaController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PopupMenuButton<String>(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                minWidth: 120,
                              ),
                              onSelected: (String valor) {
                                setState(() {
                                  _mesSeleccionado = valor;
                                  _mesController.text = valor;
                                });
                              },
                              itemBuilder: (BuildContext context) =>
                                  _meses.map((String mes) {
                                    return PopupMenuItem<String>(
                                      value: mes,
                                      child: Text(
                                        mes,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  context,
                                  "Mes",
                                  controller: _mesController,
                                  readOnly: true,
                                  isDropdown: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              context,
                              "Año",
                              controller: _anioController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Checkbox(
                            value: _aceptaTerminos,
                            onChanged: (bool? value) {
                              setState(() {
                                _aceptaTerminos = value ?? false;
                              });
                            },
                            activeColor: colorScheme.primary,
                            checkColor: colorScheme.brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                            side: BorderSide(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "He leído y acepto los Términos y condiciones y la Política de Privacidad",
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: .circular(5),
                            ),
                          ),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) {
                              return; // Si hay errores, no continúa
                            }
                            if (!_aceptaTerminos) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Debes aceptar los términos")),
                              );
                              return;
                            }

                            if (_mesSeleccionado == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Selecciona un mes")),
                              );
                              return;
                            }

                            int? dia = int.tryParse(_diaController.text);
                            int mes = int.parse(mesANumero(_mesSeleccionado!));
                            int? anio = int.tryParse(_anioController.text);

                            if (dia == null || anio == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Fecha inválida")),
                              );
                              return;
                            }

                            try {
                              DateTime fechaValida = DateTime(anio, mes, dia);

                              if (fechaValida.day != dia || fechaValida.month != mes || fechaValida.year != anio) {
                                throw Exception();
                              }
                              if (fechaValida.isAfter(DateTime.now())) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("La fecha no puede ser futura")),
                                );
                                return;
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Fecha inválida")),
                              );
                              return;
                            }

                            final fechaString = "${dia.toString().padLeft(2,'0')}/${mes.toString().padLeft(2,'0')}/$anio";

                            final userData = {
                              "nombre": _nombreController.text,
                              "apellidos": _apellidoController.text,
                              "fechaNacimiento": fechaString,
                              "email": _correoController.text,
                              "telefono": _telefonoController.text,
                              "password": _passwordController.text,
                              "idRol": 1,
                            };

                            final mensaje = await ApiService.registrar(userData);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(mensaje)),
                            );

                            if (mensaje.toLowerCase().contains("correcto") ||
                                mensaje.toLowerCase().contains("exitoso")) {
                              //Navigator.pushNamed(context, '/login');
                            }
                          },
                          child: Text(
                            "Registrarse",
                            style: TextStyle(
                              color: colorScheme.brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "¿Ya tienes cuenta? ",
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Text(
                              "Inicia sesión",
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
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

  Widget _buildTextField(
    BuildContext context,
    String label, {
    bool isPassword = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextEditingController? controller,
    bool? isObscured,
    VoidCallback? onToggle,
    bool isDropdown = false,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: TextStyle(color: colorScheme.onSurface),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Este campo es obligatorio";
          }
          if (label == "Correo") {
            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
            if (!emailRegex.hasMatch(value)) {
              return "Introduce un email válido";
            }
          }
          if (label == "Número de teléfono") {
            final phoneRegex = RegExp(r'^[679]\d{8}$');

            if (!phoneRegex.hasMatch(value)) {
              return "Debe tener 9 dígitos y empezar por 6, 7 o 9";
            }
          }
          if (label == "Contraseña") {
            final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

            if (!passwordRegex.hasMatch(value)) {
              return "Debe tener 8 caracteres, mayúscula, minúscula y número";
            }
          }
          if (label == "Repetir contraseña") {
            if (value != _passwordController.text) {
              return "Las contraseñas no coinciden";
            }
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isObscured! ? Icons.visibility_off : Icons.visibility,
                    color: colorScheme.primary.withValues(alpha: 0.6),
                  ),
                  onPressed: onToggle,
                )
              : (isDropdown ? const Icon(Icons.arrow_drop_down) : null),
          enabledBorder: OutlineInputBorder(
            borderRadius: .circular(20),
            borderSide: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: .circular(20),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        obscureText: isPassword ? (isObscured ?? true) : false,
      ),
    );
  }
}