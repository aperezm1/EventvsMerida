import 'package:flutter/foundation.dart';
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

  Widget _contenidoPrivacidad() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _paddingHorizontalContenido,
        0,
        _paddingHorizontalContenido,
        _paddingInferiorContenido,
      ),
      child: Text(
        _textoPrivacidad,
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
          child: _contenidoPrivacidad(),
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