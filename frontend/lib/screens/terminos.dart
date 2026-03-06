import 'package:flutter/material.dart';

class TerminosScreen extends StatelessWidget {
  const TerminosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Servicios'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Text(
            '''
Términos y Condiciones de Uso

Bienvenido a Eventvs Mérida. Al utilizar nuestra aplicación, aceptas los siguientes términos:

1. Objeto
Eventvs Mérida es una plataforma para la consulta y gestión de eventos culturales en Mérida.

2. Uso de la aplicación
Los usuarios se comprometen a hacer un uso adecuado de los servicios, sin vulnerar derechos de terceros ni la legislación vigente. Está prohibido el uso para fines ilícitos o fraudulentos.

3. Propiedad intelectual
Todos los derechos sobre los contenidos, imágenes, logotipos y marcas son propiedad de Eventvs Mérida, salvo que se indique lo contrario.

4. Responsabilidad
Eventvs Mérida no se responsabiliza por la exactitud de los datos de los eventos ni por daños derivados del uso de la app.

5. Modificaciones
Los presentes términos podrán ser modificados para adaptarlos a nuevas normativas o mejorar el servicio.

6. Legislación y jurisdicción
La relación se regirá por la legislación española. Para cualquier controversia, las partes se someten a los juzgados de Mérida (España).

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