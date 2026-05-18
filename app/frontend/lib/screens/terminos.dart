import 'package:flutter/foundation.dart';
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
  final ValueNotifier<int> _actualizadorScrollbar = ValueNotifier<int>(0);

  static const double _paddingSuperiorContenido = 24;
  static const double _paddingHorizontalContenido = 24;
  static const double _paddingInferiorContenido = 24;

  static const double _grosorScrollbar = 6;
  static const double _radioScrollbar = 20;
  static const double _altoMinimoScrollbar = 48;
  static const double _margenVerticalScrollbar = 0;
  static const double _margenDerechoScrollbar =
      (_paddingHorizontalContenido - _grosorScrollbar) / 2;

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
    _actualizadorScrollbar.dispose();
    super.dispose();
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _contenidoTerminos() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _paddingHorizontalContenido,
        0,
        _paddingHorizontalContenido,
        _paddingInferiorContenido,
      ),
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
    final contenido = Padding(
      padding: const EdgeInsets.only(top: _paddingSuperiorContenido),
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          _actualizadorScrollbar.value++;
          return false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: _contenidoTerminos(),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            contenido,
            Positioned(
              top: _paddingSuperiorContenido,
              right: _margenDerechoScrollbar,
              bottom: _paddingInferiorContenido,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _scrollController,
                    _actualizadorScrollbar,
                  ]),
                  builder: (context, child) {
                    if (!_scrollController.hasClients) {
                      return const SizedBox.shrink();
                    }

                    final posicion = _scrollController.position;

                    if (!posicion.hasContentDimensions) {
                      return const SizedBox.shrink();
                    }

                    final maxScroll = posicion.maxScrollExtent;

                    if (maxScroll <= 0) {
                      return const SizedBox.shrink();
                    }

                    final altoDisponible = constraints.maxHeight -
                        _paddingSuperiorContenido -
                        _paddingInferiorContenido;

                    final altoCarril =
                        altoDisponible - (_margenVerticalScrollbar * 2);

                    if (altoCarril <= 0) {
                      return const SizedBox.shrink();
                    }

                    final altoContenido = posicion.extentInside + maxScroll;

                    final altoScrollbar =
                    (posicion.extentInside / altoContenido * altoCarril)
                        .clamp(_altoMinimoScrollbar, altoCarril)
                        .toDouble();

                    final porcentajeScroll =
                    (_scrollController.offset / maxScroll)
                        .clamp(0.0, 1.0)
                        .toDouble();

                    final desplazamientoScrollbar =
                        (altoCarril - altoScrollbar) * porcentajeScroll;

                    return SizedBox(
                      width: _grosorScrollbar,
                      height: altoDisponible,
                      child: Stack(
                        children: [
                          Positioned(
                            top: _margenVerticalScrollbar +
                                desplazamientoScrollbar,
                            right: 0,
                            child: Container(
                              width: _grosorScrollbar,
                              height: altoScrollbar,
                              decoration: BoxDecoration(
                                color: _cs.primary,
                                borderRadius:
                                BorderRadius.circular(_radioScrollbar),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
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