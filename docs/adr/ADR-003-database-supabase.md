# ADR-003: Selección de Supabase para la base de datos y autenticación

## Contexto
El sistema requiere gestión de usuarios, catálogo de eventos y funcionalidades
asociadas a la ubicación, con necesidad de autenticación y operaciones
relacionales. Debe poder escalar, ser rápido, y facilitar la integración con el
backend y el frontend.

## Decisión
Se utiliza **Supabase** como la solución de base de datos (PostgreSQL),
autenticación y servicios en tiempo real.

## Alternativas consideradas
- **MongoDB:** Descartado por desconocimiento.
- **JDBC:** Descartado, ya que aunque provee acceso directo y personalizado a
la base de datos, requiere más esfuerzo de configuración, administración y
mantenimiento, además de no incluir servicios integrados de autenticación ni API REST listas para usar.

## Consecuencias
El equipo puede aprovechar autenticación, API RESTful y gestión de usuarios
de Supabase, simplificando la conexión con el frontend y backend. El sistema
podrá escalar y adaptarse a futuras necesidades sin rehacer gran parte de la
arquitectura.

## Fecha / Estado
- Fecha de decisión: 11/11/2025
- Estado: Aprobada