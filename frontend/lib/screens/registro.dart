import 'package:flutter/material.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  bool _aceptaTerminos = false;
  bool _oscurecerPassword = true;
  bool _oscurecerRepetirPassword = true;
  String? _mesSeleccionado;
  final List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  final TextEditingController _mesController = TextEditingController();

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
                color: colorScheme.brightness == Brightness.dark ? Colors.black : Colors.white,
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTextField(context, "Nombre")),
                        const SizedBox(width: 15), // Espacio horizontal entre los dos cuadros
                        Expanded(child: _buildTextField(context, "Apellido")),
                      ],
                    ),
                    _buildTextField(context, "Correo"),
                    _buildTextField(context, "Contraseña", isPassword: true, isObscured: _oscurecerPassword,
                      onToggle: () {
                        setState(() {
                          _oscurecerPassword = !_oscurecerPassword;
                        });
                      },
                    ),
                    _buildTextField(context, "Repetir contraseña", isPassword: true, isObscured: _oscurecerRepetirPassword,
                      onToggle: () {
                        setState(() {
                          _oscurecerRepetirPassword = !_oscurecerRepetirPassword;
                        });
                      },
                    ),
                    _buildTextField(context, "Número de teléfono"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(context, "Día")),
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
                            itemBuilder: (BuildContext context) => _meses.map((String mes) {
                              return PopupMenuItem<String>(
                                  value: mes,
                                  child: Text(mes, style: TextStyle(color: colorScheme.onSurface)),
                              );
                            }).toList(),
                            child: AbsorbPointer(
                              child: _buildTextField(context, "Mes", controller: _mesController, readOnly: true, isDropdown: true),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextField(context, "Año")),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Checkbox(
                          value: _aceptaTerminos, // Aquí deberías usar una variable de estado
                          onChanged: (bool? value) {
                            setState(() {
                              _aceptaTerminos = value ?? false;
                            });
                          },
                          activeColor: colorScheme.primary,
                          checkColor: colorScheme.brightness == Brightness.dark ? Colors.black : Colors.white,
                          side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                        Expanded(
                          child: Text(
                            "He leído y acepto los Términos y condiciones y la Política de Privacidad",
                            style: TextStyle(color: colorScheme.onSurface, fontSize: 12),
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
                          shape: RoundedRectangleBorder(borderRadius: .circular(5)),
                        ),
                        onPressed: () {
                          if(_aceptaTerminos) {
                            print("Registrando...");
                          }
                        },
                        child: Text(
                          "Registrarse",
                          style: TextStyle(
                            color: colorScheme.brightness == Brightness.dark ? Colors.black : Colors.white,
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
}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
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
            borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.4)),
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