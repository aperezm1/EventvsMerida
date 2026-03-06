import 'package:flutter/material.dart';

class PrivacidadScreen extends StatelessWidget {
  const PrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Text(
            '''
Política de Privacidad

1. Responsable del tratamiento
Eventvs Mérida es responsable de tus datos personales. Puedes contactar a través del email: info@eventvsmerida.com

2. Datos recopilados
Recopilamos los datos proporcionados en el registro (nombre, apellidos, correo electrónico, fecha de nacimiento y teléfono) y únicamente empleamos cookies técnicas.

3. Finalidad
Tus datos se emplean para la gestión de usuarios y eventos. No compartimos tu información con terceros, salvo requerimiento legal.

4. Legitimación
La base legal para el tratamiento es tu consentimiento al registrarte.

5. Conservación
Tus datos se conservarán sólo mientras seas usuario registrado o por requerimientos legales.

6. Derechos
Puedes ejercitar tus derechos de acceso, rectificación, cancelación y oposición escribiendo a info@eventvsmerida.com

7. Seguridad
Aplicamos medidas técnicas y organizativas para proteger tus datos de accesos no autorizados.

8. Cambios en la política
Esta política puede actualizarse en el futuro. Te notificaremos si hay cambios relevantes.

Última actualización: 06/03/2026
            ''',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}