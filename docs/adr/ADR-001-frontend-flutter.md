# ADR-001: Selección de Flutter para el desarrollo del frontend móvil

## Contexto
Eventvs Mérida es una aplicación móvil que debe estar disponible para
Android. El equipo cuenta con experiencia en Flutter, y el objetivo es
desarrollar un único código base reutilizable que agilice el desarrollo y el
mantenimiento de la app.

## Decisión
El frontend móvil se desarrollará utilizando **Flutter** como framework principal.

## Alternativas consideradas
- **React Native:** Descartado por menor experiencia del equipo y por posibles
complicaciones en la integración nativa de mapas y geolocalización.
- **Desarrollo nativo:** Descartado por requerir doble esfuerzo y duplicar el
código en vez de maximizar la productividad y reutilización.

## Consecuencias
El desarrollo será más eficiente, con una sola base de código en Dart para
cualquier sistema operativo. Se podrá lanzar el prototipo más rápidamente y
aprovechar los recursos de la comunidad Flutter.

## Fecha / Estado
- Fecha de decisión: 11/11/2025
- Estado: Aprobada