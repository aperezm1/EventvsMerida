import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controlador_tema.dart';

class Usuario {
  final String nombre;
  final String? fotoUrl;
  Usuario({required this.nombre, this.fotoUrl});
}

class Perfil extends StatelessWidget {
  final Usuario? usuario;

  const Perfil({Key? key, this.usuario}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Encabezado con información del usuario o invitación a registrarse
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          color: colorScheme.primary,
          child: usuario == null ? Column(
            // En caso de no estar iniciado sesión
            children: [
              Text(
                'Regístrate o inicia sesión',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Fila de botones para registrarse o iniciar sesión
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón de registro
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.onPrimary),
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: () => context.push("/registro"),
                    child: const Text('Registrarse'),
                  ),
                  const SizedBox(width: 12),

                  // Botón de inicio de sesión
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.onPrimary,
                      foregroundColor: colorScheme.primary,
                    ),
                    onPressed: () => context.push("/login"),
                    child: const Text('Iniciar sesión'),
                  ),
                ],
              )
            ],
          ) : Column(
            // En caso de estar iniciado sesión, mostrar información del usuario
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.onPrimary.withOpacity(0.9),
                backgroundImage: usuario!.fotoUrl != null
                    ? NetworkImage(usuario!.fotoUrl!)
                    : null,
                radius: 32,
                child: usuario!.fotoUrl == null
                    ? Icon(Icons.person,
                    color: colorScheme.primary, size: 34)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                usuario!.nombre,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),

        // Contenido principal
        Expanded(
          child: ListView(
            children: [
              const SizedBox(height: 24),

              // Sección de preferencias
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'PREFERENCIAS',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildPreferencias(context, colorScheme, usuario),

              // Separador
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Divider(
                  color: colorScheme.primary,
                  thickness: 2,
                ),
              ),

              // Sección de información legal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'INFORMACIÓN LEGAL',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildLegal(context, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildPreferencias(BuildContext context, ColorScheme colorScheme, Usuario? usuario) {
    final isRegistrado = usuario != null;

    return Column(
      children: isRegistrado ? [
        _buildItem(Icons.account_circle, "Cuenta"),
        _buildItem(
          Icons.dark_mode,
          "Modo Oscuro",
          trailing: Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            activeColor: colorScheme.secondary,
            onChanged: (v) {
              themeController.value = v ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        ),
        _buildItem(Icons.bookmark_border, "Eventos guardados"),
        _buildItem(Icons.notifications, "Preferencias de notificaciones"),
      ] : [
        _buildItem(
          Icons.dark_mode,
          "Modo Oscuro",
          trailing: Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            activeColor: colorScheme.secondary,
            onChanged: (v) {
              themeController.value = v ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildLegal(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildItem(Icons.file_copy, "Términos y servicios"),
        _buildItem(Icons.privacy_tip, "Política de privacidad"),
      ],
    );
  }

  static Widget _buildItem(IconData icono, String titulo,
      {Widget? trailing}) {
    return ListTile(
      leading: Icon(icono),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      onTap: () {},
    );
  }
}