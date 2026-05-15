# Eventvs Mérida — Frontend (Flutter)

Frontend multiplataforma para unificar eventos y actividades de Mérida.

## 🚀 Instalación y arranque

### Requisitos
- Flutter con Dart compatible con el SDK `^3.10.4`
- Git
- Android Studio, VS Code o el IDE que prefieras
- Un dispositivo, emulador o navegador según el target que vayas a ejecutar

### Pasos

```bash
# 1. Obtener dependencias
flutter pub get

# 2. Ejecutar en desarrollo
flutter run

# Windows
flutter run -d windows

# Web
flutter run -d chrome

# 3. Generar build para producción
flutter build apk
flutter build web
```

La aplicación consume la API REST del proyecto.

## 📁 Estructura del proyecto

```
assets/images/              # Logos e imágenes de la app
lib/
├── main.dart               # Punto de entrada
├── core/
│   ├── app.dart            # Configuración global de la app
│   ├── router/             # Navegación con go_router
│   └── theme/              # Temas claro/oscuro y controlador de tema
├── models/                 # Modelos de datos (evento, usuario, categoría, API)
├── screens/                # Pantallas principales y flujos de usuario
├── services/               # API, sesión, almacenamiento seguro y geocoding
├── utils/                  # Utilidades de fechas, validaciones y ayudas varias
└── widgets/                # Componentes reutilizables
```

## ✨ Características

- Navegación declarativa con `go_router`, con ruta inicial de splash y `ShellRoute` para las secciones principales.
- Catálogo de eventos con búsqueda, filtrado, paginación y vista de detalle.
- Calendario de eventos y mapa interactivo con ubicaciones sobre OpenStreetMap.
- Autenticación, registro, perfil de usuario y persistencia de sesión.
- Eventos guardados, administración de eventos y formulario para crear o editar eventos.
- Selección de ubicación con geocodificación inversa y soporte para abrir direcciones externas.
- Compartición de eventos y enlaces, además de tutorial guiado para primeras visitas.
- Gestión de tema claro/oscuro y localización en español.

## 🛠 Tecnologías

- Flutter
- Dart `^3.10.4`
- go_router
- http
- shared_preferences
- flutter_secure_storage
- flutter_map y latlong2
- table_calendar
- intl
- url_launcher
- share_plus
- image_picker
- tutorial_coach_mark

## 🔧 Configuración

La configuración principal está embebida en el código del frontend. Si necesitas cambiar la API base, edita `lib/services/api_service.dart`.

- Assets principales: `assets/images/`

## 🐳 Compilación y despliegue

El proyecto puede desplegarse como app móvil, web o escritorio según el target de Flutter. Para generar artefactos habituales:

```bash
flutter build apk
flutter build web
flutter build windows
```

Para el despliegue web se usa la salida de `build/web`.

## 🔗 Enlaces

- Repositorio: https://github.com/Null-Pointers-Albarregas/EventvsMerida

---

Desarrollado por **Adrián Pérez Morales**, **David Muñoz Collado** y **Eva Retamar Muñoz**  
IES Albarregas · Mérida, Extremadura
