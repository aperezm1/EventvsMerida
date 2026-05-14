# Eventvs Mérida — Landing Page

Landing page oficial de la aplicación **Eventvs Mérida**, desarrollada con **Angular 19**.

## 🚀 Instalación y arranque

### Requisitos
- Node.js 18+ 
- npm 9+

### Pasos

```bash
# 1. Instalar dependencias
npm install

# 2. Arrancar en desarrollo
npm start

# 3. Build de producción
npm run build
```

La app arrancará en `http://localhost:4200`

## 📁 Estructura del proyecto

```
src/
├── app/
│   ├── components/
│   │   ├── navbar/          # Navbar fija con scroll detection y selector de idiomas
│   │   ├── hero/            # Hero con parallax y animaciones de entrada
│   │   ├── about/           # Sección "Qué es la app"
│   │   ├── features/        # Grid de funcionalidades
│   │   ├── team/            # Tarjetas del equipo
│   │   └── download/        # Descarga APK + repo + footer
│   ├── core/
│   │   ├── directives/      # Directivas (reveal.directive.ts)
│   │   ├── models/          # Modelos de datos
│   │   └── services/        # Servicios (language.service.ts)
│   ├── app.component.ts
│   ├── app.component.html
│   ├── app.config.ts        # Configuración de Angular
│   ├── main.ts
│   ├── styles.scss          # Estilos globales + variables CSS
│   └── index.html
public/
├── assets/
│   ├── *.svg                # Banderas SVG de idiomas (es.svg, en.svg, pt.svg, fr.svg)
│   ├── *.png, *.jpg         # Imágenes estáticas
│   └── logo.jpeg            # Logo de la aplicación
├── downloads/               # APK y descargas
└── i18n/
    ├── es.json              # Traducciones en español
    ├── en.json              # Traducciones en inglés
    ├── pt.json              # Traducciones en portugués
    └── fr.json              # Traducciones en francés
```

## ✨ Animaciones implementadas

- **Hero**: Entrada escalonada de título, subtítulo y CTAs con `@keyframes`
- **Parallax**: El fondo del hero hace parallax al hacer scroll
- **Scroll reveal**: Cada sección aparece con física suave al entrar en viewport (Intersection Observer)
- **Hover effects**: Cards con lift, glow y líneas animadas
- **Particles**: Partículas flotantes en el hero
- **Orbs**: Esferas de luz animadas en fondos
- **Language selector**: Menú personalizado con banderas SVG para cambiar idioma

## � Idiomas

El proyecto soporta múltiples idiomas con selector personalizado en la navbar:
- **Español** (es.svg)
- **English** (en.svg)
- **Portugués** (pt.svg)
- **Francés** (fr.svg)

El selector de idioma muestra la bandera del país y permite cambiar dinámicamente el idioma.

## �🎨 Diseño

- **Colores**: Dorado `#F5A623` + Azul `#2B6CB0` + Darkblue `#080C12`
- **Tipografías**: Bebas Neue (títulos) + Barlow (cuerpo) + Barlow Condensed (UI)
- **Tema**: Dark con efectos cinematográficos y glassmorphism en componentes
- **UI Components**: Selector de idioma personalizado, navbar sticky, menú móvil hamburguesa

## 📲 Links

- **Repositorio**: https://github.com/Null-Pointers-Albarregas/EventvsMerida
- **APK**: https://github.com/Null-Pointers-Albarregas/EventvsMerida/releases/download/Alpha/eventvs-merida.apk

---

Desarrollado por **Adrián Pérez Morales**, **David Muñoz Collado** y **Eva Retamar Muñoz**  
IES Albarregas · Mérida, Extremadura
