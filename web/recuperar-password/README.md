# Eventvs Mérida — Restablecer contraseña

Página web oficial de **Eventvs Mérida** para el restablecimiento de contraseñas. Esta vista permite crear una nueva contraseña a partir de un token válido recibido en la URL.

## 🚀 Instalación y arranque

### Requisitos
- Navegador moderno
- Conexión a internet para cargar **Bootstrap 5.3.3** y **SweetAlert2** desde CDN
- Un token válido en la URL para completar el proceso

### Pasos

```bash
# 1. Abrir el proyecto en un servidor local o con Live Server

# 2. Cargar la página en el navegador

# 3. Pasar el token en la URL
```

Ejemplo:

```text
index.html?token=TU_TOKEN_AQUI
```

La interfaz se puede abrir directamente desde un servidor local y realiza la petición al backend de Eventvs Mérida para actualizar la contraseña.

## 📁 Estructura del proyecto

```
.
├── index.html              # Vista principal de restablecimiento
├── script.js               # Lógica del formulario, validación y petición al backend
├── style.css               # Estilos visuales, animaciones y responsive
└── assets/
    └── img/
        ├── icon.png       # Favicon de la página
        └── logo.gif       # Logo animado de Eventvs Mérida
```

## ✨ Funcionalidades implementadas

- **Validación del formulario**: comprueba longitud, complejidad y coincidencia entre ambas contraseñas
- **Mostrar/ocultar contraseña**: botón de ojo para alternar la visibilidad de cada campo
- **Gestión de token**: toma el token desde la query string y lo envía al backend
- **Feedback visual**: notificaciones tipo toast con **SweetAlert2**
- **Estado de éxito**: mensaje visual con check animado cuando el cambio se completa
- **Diseño responsive**: interfaz adaptada a móvil y escritorio

## 🎨 Diseño

- **Tema**: claro, limpio y centrado en la acción principal
- **Estilo visual**: tarjetas con sombra suave, bordes redondeados y fondo con degradado radial
- **Componentes**: input de contraseña con botón integrado y estados de validación nativos de Bootstrap
- **Animaciones**: check animado, entrada suave de elementos y feedback visual inmediato

## 📲 Uso

1. Accede a la página con un token válido en la URL.
2. Escribe la nueva contraseña y confírmala.
3. Pulsa **Cambiar contraseña**.
4. Si todo es correcto, verás la confirmación de éxito.

---

Desarrollado por **Adrián Pérez Morales**, **David Muñoz Collado** y **Eva Retamar Muñoz**  
IES Albarregas · Mérida, Extremadura
