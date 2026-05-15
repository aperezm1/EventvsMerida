import 'package:flutter/material.dart';

/// Pantalla de la Política de Privacidad de la app.
///
/// @author: Eva Retamar
/// @author: Adrián Pérez
/// @author: David Muñoz
class Privacidad extends StatefulWidget {
  const Privacidad({super.key});

  @override
  State<Privacidad> createState() => _PrivacidadState();
}

class _PrivacidadState extends State<Privacidad> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================
  ColorScheme get _cs => Theme.of(context).colorScheme;

  static const String _textoPrivacidad = '''
Política de Privacidad

En Eventvs Mérida nos comprometemos a proteger tu privacidad y a tratar tus datos personales de forma transparente y segura.

1. Responsable del tratamiento  
El responsable del tratamiento de los datos es Eventvs Mérida.  
Correo de contacto: info@eventvsmerida.com

2. Datos personales tratados  
Recopilamos los datos que nos facilitas durante el registro y uso de la aplicación, como nombre, apellidos, correo electrónico, fecha de nacimiento y teléfono. La aplicación únicamente utiliza cookies técnicas necesarias para su funcionamiento.

3. Finalidad del tratamiento  
Los datos se tratan con la finalidad de gestionar tu cuenta de usuario, facilitar el acceso a los servicios de la aplicación y mejorar la experiencia de uso. No se utilizarán para fines distintos ni se cederán a terceros, salvo obligación legal.

4. Base legal  
El tratamiento de tus datos se basa en tu consentimiento, otorgado al registrarte y utilizar la aplicación, así como en la correcta prestación del servicio.

5. Conservación de los datos  
Los datos personales se conservarán mientras mantengas tu condición de usuario registrado y, posteriormente, durante los plazos legalmente exigidos.

6. Derechos del usuario  
Puedes ejercer tus derechos de acceso, rectificación, supresión, limitación del tratamiento y oposición, así como retirar tu consentimiento en cualquier momento, escribiendo a info@eventvsmerida.com

7. Seguridad de la información  
Eventvs Mérida aplica las medidas técnicas y organizativas necesarias para garantizar la seguridad y confidencialidad de los datos personales y evitar su pérdida, acceso no autorizado o uso indebido.

8. Cambios en la política de privacidad  
Esta política podrá ser actualizada en función de cambios legales o mejoras del servicio. En caso de modificaciones relevantes, se informará a los usuarios a través de la aplicación.

Última actualización: mayo de 2026
''';

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _contenidoPrivacidad() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Text(
          _textoPrivacidad,
          style: TextStyle(
            color: _cs.onSurface,
            fontSize: 16,
          ),
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 8.0),
        color: _cs.primary,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: _cs.surface),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Center(
              child: Text(
                'Política de Privacidad',
                style: TextStyle(
                  color: _cs.surface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cs.surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _contenidoPrivacidad()),
        ],
      ),
    );
  }
}