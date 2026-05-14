# Eventvs Mérida — Restablecer contraseña

Página web de restablecimiento de contraseña para Eventvs Mérida.
Permite introducir una nueva contraseña usando un token recibido por URL y enviar la actualización al backend.

## 🚀 Instalación y arranque

### Requisitos
- Navegador moderno
- Conexión a internet para cargar **Bootstrap 5.3.3** y **SweetAlert2** desde CDN
- Un token válido en la URL para completar el proceso
- Servir la carpeta con servidor local para cargar correctamente los archivos de **i18n/**

### Pasos

```bash
# 1. Abrir el proyecto en un servidor local o con Live Server

# 2. Cargar la página en el navegador

# 3. Pasar el token en la URL
```

Ejemplo:

```text
http://127.0.0.1:5500/index.html?token=TU_TOKEN_AQUI
```

La interfaz se puede abrir directamente desde un servidor local y realiza la petición al backend de Eventvs Mérida para actualizar la contraseña.

## 📁 Estructura del proyecto

```
.
├── index.html              # Vista principal de restablecimiento
├── script.js               # Lógica del formulario, validación y petición al backend
├── style.css               # Estilos visuales, animaciones y responsive
├── i18n/
│   ├── es.json             # Traducciones en español
│   ├── en.json             # Traducciones en inglés
│   ├── pt.json             # Traducciones en portugués
│   └── fr.json             # Traducciones en francés
└── assets/
    └── img/
    ├── icon.png        # Favicon de la página
    ├── logo.gif        # Logo animado de Eventvs Mérida
    ├── es.svg          # Bandera español
    ├── en.svg          # Bandera inglés
    ├── pt.svg          # Bandera portugués
    └── fr.svg          # Bandera francés
```

## ✨ Funcionalidades implementadas

- **Validación del formulario**: comprueba longitud, complejidad y coincidencia entre ambas contraseñas
- **Mostrar/ocultar contraseña**: botón de ojo para alternar la visibilidad de cada campo
- **Gestión de token**: toma el token desde la query string y lo envía al backend
- **Regla de contraseña**: mínimo 8 caracteres, una mayúscula, una minúscula, un número y un símbolo (`# @ $ ! % * ? &`)
- **Feedback visual**: notificaciones tipo toast con **SweetAlert2**
- **Estado de éxito**: mensaje visual con check animado cuando el cambio se completa
- **Internacionalización (i18n)**: selector de idioma con soporte para `es`, `en`, `pt` y `fr`
- **Persistencia de idioma**: guarda el idioma seleccionado en `localStorage` (`lang`)
- **Manejo de tokens inválidos/caducados**: controla respuestas `USED_TOKEN`, `EXPIRED_TOKEN` e `INVALID_TOKEN`
- **Diseño responsive**: interfaz adaptada a móvil y escritorio

## 🎨 Diseño

- **Tema**: claro, limpio y centrado en la acción principal
- **Estilo visual**: tarjetas con sombra suave, bordes redondeados y fondo con degradado radial
- **Componentes**: input de contraseña con botón integrado y estados de validación nativos de Bootstrap
- **Animaciones**: check animado, entrada suave de elementos y feedback visual inmediato

## 📲 Uso

1. Accede a la página con un token válido en la URL.
2. (Opcional) Selecciona el idioma desde el desplegable superior.
3. Escribe la nueva contraseña y confírmala.
4. Pulsa **Cambiar contraseña**.
5. Si todo es correcto, verás la confirmación de éxito.

---

Desarrollado por **Adrián Pérez Morales**, **David Muñoz Collado** y **Eva Retamar Muñoz**  
IES Albarregas · Mérida, Extremadura
