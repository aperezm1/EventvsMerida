# Eventvs Mérida — Scripts de Eventos

Scripts auxiliares de **Eventvs Mérida** para descargar eventos desde un calendario iCal/ICS, sanear los datos y subirlos a la API de la aplicación.

## 🚀 Instalación y ejecución

### Requisitos

- Python 3.10+
- pip

### Dependencias

```bash
pip install requests beautifulsoup4 rich python-dotenv playwright
python -m playwright install chromium
```

### Variables de entorno

Crear un archivo `.env` en la raíz de la carpeta `scripts/`:

```env
EVENTVSMERIDA_EMAIL=correo_admin
EVENTVSMERIDA_PASSWORD=password_admin
```

## ▶️ Orden de ejecución

Los scripts deben ejecutarse **desde la raíz de la carpeta `scripts/`**, no desde dentro de `src/`.

### 1. Descargar eventos desde el calendario ICS

```bash
python src/scraper_calendario.py --ics-url "https://TU_DOMINIO/events/?ical=1" --out data/raw/eventos_bruto.json
```

Ejemplo:

```bash
python src/scraper_calendario.py --ics-url "https://merida.es/agenda/lista/?tribe-bar-date=2026-02-01&ical=1" --out data/raw/eventos_bruto.json
```

### 2. Sanear y normalizar eventos

```bash
python src/saneador_caracteres.py data/raw/eventos_bruto.json data/processed/eventos_saneados.json
```

### 3. Subir eventos a la API

```bash
python src/subir_eventos.py data/processed/eventos_saneados.json
```

## 📁 Estructura del proyecto

```text
scripts/
├── .env                          # Variables de entorno con credenciales
├── .gitignore                    # Archivos y carpetas ignorados por Git
├── README.md                     # Documentación de los scripts
│
├── src/
│   ├── __init__.py               # Marca src como paquete Python
│   ├── maps_geocoder.py          # Geocodificación con Google Maps y Playwright
│   ├── saneador_caracteres.py    # Limpieza y normalización del JSON
│   ├── scraper_calendario.py     # Descarga y parseo de eventos desde iCal/ICS
│   └── subir_eventos.py          # Subida de eventos saneados a la API
│
├── data/
│   ├── raw/
│   │   └── eventos_bruto.json    # JSON bruto generado desde el calendario ICS
│   │
│   └── processed/
│       └── eventos_saneados.json # JSON limpio y listo para subir
│
└── docs/
    └── meses_ejecutar_script.txt # Notas sobre meses o fechas de ejecución
```

## 🧩 Descripción de los scripts

- `scraper_calendario.py`: descarga eventos desde una URL iCal/ICS y genera `data/raw/eventos_bruto.json`.
- `saneador_caracteres.py`: limpia textos, normaliza fechas y categorías, y genera `data/processed/eventos_saneados.json`.
- `maps_geocoder.py`: obtiene coordenadas de localizaciones usando Google Maps con Playwright. Lo usa internamente `subir_eventos.py`.
- `subir_eventos.py`: lee el JSON saneado, obtiene coordenadas e imagen si es posible, inicia sesión como administrador y sube los eventos a la API.

## 🔗 Links

- **Repositorio**: https://github.com/Null-Pointers-Albarregas/EventvsMerida

---

Desarrollado por **Adrián Pérez Morales**, **David Muñoz Collado** y **Eva Retamar Muñoz**  
IES Albarregas · Mérida, Extremadura