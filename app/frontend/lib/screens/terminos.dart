import 'package:flutter/material.dart';

/// Pantalla de Términos y Condiciones de Uso de la app.
///
/// @author: Eva Retamar
/// @author: Adrián Pérez
/// @author: David Muñoz
class Terminos extends StatefulWidget {
  const Terminos({super.key});

  @override
  State<Terminos> createState() => _TerminosState();
}

class _TerminosState extends State<Terminos> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  final ScrollController _scrollController = ScrollController();

  ColorScheme get _cs => Theme.of(context).colorScheme;

  static const String _textoTerminos = '''
Términos y Condiciones de Uso

Bienvenido a Eventvs Mérida. El acceso y uso de esta aplicación implica la aceptación de los presentes Términos y Condiciones.

1. Finalidad de la aplicación  
Eventvs Mérida es una plataforma informativa destinada a la consulta, difusión y gestión de eventos culturales, sociales y de ocio que tienen lugar en la ciudad de Mérida.

2. Uso del servicio  
El usuario se compromete a utilizar la aplicación de forma responsable, conforme a la ley, la buena fe y el orden público. Queda prohibido cualquier uso que pueda dañar, sobrecargar o perjudicar el correcto funcionamiento de la aplicación o los derechos de terceros.

3. Propiedad intelectual  
Los contenidos, diseños, textos, logotipos e imágenes disponibles en la aplicación son titularidad de Eventvs Mérida o de terceros que han autorizado su uso, y se encuentran protegidos por la normativa vigente en materia de propiedad intelectual.

4. Contenidos y responsabilidad  
Eventvs Mérida realiza sus mejores esfuerzos para mantener la información actualizada y veraz, pero no garantiza la absoluta exactitud o disponibilidad permanente de los datos publicados. La aplicación no se hace responsable de posibles cambios, cancelaciones o incidencias relacionadas con los eventos.

5. Modificaciones  
Eventvs Mérida se reserva el derecho a modificar estos términos en cualquier momento, así como a actualizar o mejorar las funcionalidades de la aplicación.

6. Legislación aplicable  
Estos términos se rigen por la legislación española. Para la resolución de cualquier conflicto, las partes se someten a los juzgados y tribunales de Mérida (España).

Última actualización: mayo de 2026
''';

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _contenidoTerminos() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Text(
        _textoTerminos,
        style: TextStyle(
          color: _cs.onSurface,
          fontSize: 16,
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
                'Términos y Servicios',
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

  Widget _buildContenidoConScroll() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: RawScrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 6,
        radius: const Radius.circular(20),
        mainAxisMargin: 0,
        crossAxisMargin: 4,
        thumbColor: _cs.primary,
        trackColor: _cs.primary.withValues(alpha: 0.18),
        trackBorderColor: Colors.transparent,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: _contenidoTerminos(),
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
          Expanded(
            child: _buildContenidoConScroll(),
          ),
        ],
      ),
    );
  }
}