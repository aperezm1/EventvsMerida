# Eventvs Mérida — Panel de administración

Panel de administración web de **Eventvs Mérida**. Este proyecto está construido con **HTML**, **CSS**, **JavaScript vanilla**, **Bootstrap** y la plantilla **SB Admin**, y consume una API REST externa.

## 🚀 Instalación y arranque

### Requisitos
- Navegador moderno
- Un servidor estático local o extensión tipo Live Server en VS Code
- Acceso a la API desplegada en Render

### Pasos

```bash
# Opción 1: abrir con Live Server desde VS Code

# Opción 2: servir la carpeta de forma local
npx serve .

# Opción 3: servidor simple con Python
python -m http.server 8000
```

Una vez levantado el servidor, abre la raíz del proyecto en el navegador. La pantalla inicial es `index.html` y el login está en `html/login.html`.

## 📁 Estructura del proyecto

```text
index.html                     # Panel principal
api/
├── geoapify.js                # Endpoint para autocomplete de direcciones con Geoapify
assets/
├── img/
│   ├── logo-eventvs-merida.jpeg
│   └── logo-eventvs-merida-no-bg.png
css/
├── styles.css                 # Estilos globales y personalizaciones de SB Admin
html/
├── login.html                 # Pantalla de acceso
├── usuarios.html              # Gestión de usuarios
├── eventos.html               # Gestión de eventos
├── organizadores.html         # Gestión de organizadores
├── categorias.html            # Gestión de categorías
└── roles.html                 # Gestión de roles
js/
├── scripts.js                 # Lógica común: auth, helpers, validaciones, logout
├── login.js                   # Inicio de sesión
├── index.js                   # Dashboard y contadores
├── usuarios.js                # CRUD de usuarios
├── eventos.js                 # CRUD de eventos
├── organizadores.js           # CRUD de organizadores
├── categorias.js              # CRUD de categorías
├── roles.js                   # CRUD de roles
├── grafico-barras.js          # Gráfico de barras
└── grafico-tarta.js           # Gráfico de tarta
```

## ✨ Funcionalidades

- **Autenticación** con sesión y cierre de sesión desde la barra superior.
- **Dashboard** con tarjetas de resumen para usuarios, eventos, organizadores, categorías y roles.
- **CRUD completo** para usuarios, eventos, organizadores, categorías y roles.
- **Validaciones de formulario** con Bootstrap y utilidades compartidas.
- **Gráficos** para visualizar datos del panel.
- **Carga de imágenes** con validación de formato y tamaño.
- **Búsqueda de direcciones** mediante una función serverless en `api/geoapify.js`.

## 🌐 API y configuración

El frontend consume una API externa definida en `js/scripts.js`:

```javascript
window.APP_CONFIG = {
    API_BASE: "https://eventvsmerida-x2t1.onrender.com/api/",
};
```

La ruta `api/geoapify.js` requiere la variable de entorno `GEOAPIFY_KEY` para funcionar correctamente.

## 🖼️ Recursos

El proyecto usa el logo de Eventvs Mérida en `assets/img/` y dependencias externas desde CDN para Bootstrap, Font Awesome y Simple Datatables.

## 📌 Vistas incluidas

- `index.html`
- `html/login.html`
- `html/usuarios.html`
- `html/eventos.html`
- `html/organizadores.html`
- `html/categorias.html`
- `html/roles.html`

---

Desarrollado por **Adrián Pérez Morales**, **David Muñoz Collado** y **Eva Retamar Muñoz**  
IES Albarregas · Mérida, Extremadura