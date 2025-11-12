# ADR-002: Selección de Spring Boot para el backend

## Contexto
Se requiere un backend robusto capaz de gestionar lógica de negocio,
operaciones seguras, integración futura con otros sistemas (redes sociales,
pagos) y facilidad de escalabilidad para las funciones clave de la app Eventvs
Mérida.

## Decisión
El backend se desarrollará sobre **Spring Boot**, utilizando Java, para
proporcionar API RESTful y gestionar toda la lógica de negocio de la
aplicación

## Alternativas consideradas
- **Java puro (sin framework):** Descartado por menor productividad, mayor carga de configuración manual y ausencia de herramientas integradas para API REST, seguridad y gestión de dependencias.
- **Node.js (Express):** Descartado por menor experiencia del equipo y preferencia por ecosistema Java, además de buscar aprovechar la madurez y comunidad de Spring Boot.

## Consecuencias
Se aprovecharán las capacidades empresariales, seguridad y modularidad de
Spring Boot; además, el equipo podrá integrar el backend con otros servicios y
ampliar la lógica sin grandes cambios estructurales.

## Fecha / Estado
- Fecha de decisión: 11/11/2025
- Estado: Aprobada