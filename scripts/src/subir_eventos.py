"""
Carga eventos saneados a la API de EventvsMérida.

Este script lee un JSON de eventos saneados, completa cada evento con imagen y
coordenadas si es posible, inicia sesión como administrador y publica los eventos
en la API de EventvsMérida.

Requisitos:
    pip install requests beautifulsoup4 rich python-dotenv

Uso:
    python src/subir_eventos.py data/processed/eventos_saneados.json

Variables de entorno opcionales:
    EVENTVSMERIDA_EMAIL
    EVENTVSMERIDA_PASSWORD

Nota:
    Para geocodificación se usa MapsGeocoder desde maps_geocoder.py.

@author Eva Retamar
@author David Muñoz
@author Adrián Pérez
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import random
import re
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress
from rich.table import Table
from rich.text import Text

try:
    from dotenv import load_dotenv
except ImportError:
    load_dotenv = None


console = Console()
logger = logging.getLogger(__name__)

DEFAULT_API_URL = "https://eventvsmerida-x2t1.onrender.com/api/eventos/add"
DEFAULT_HTTP_TIMEOUT_SECONDS = 10
DEFAULT_IMAGE_TIMEOUT_SECONDS = 20
DEFAULT_GEOCODER_NAV_TIMEOUT_MS = 8_000
DEFAULT_USER_IDS = (4, 5, 61)
DEFAULT_CATEGORY_ID = 12

REQUEST_HEADERS = {"User-Agent": "Mozilla/5.0"}
JSON_ENCODINGS = ("utf-8", "utf-8-sig", "cp1252", "latin-1")

PreparedEvent = dict[str, Any]
Coordinates = tuple[float, float]


@dataclass
class UploadStats:
    """Agrupa las estadísticas finales de subida."""

    uploaded: int = 0
    failed: int = 0

    @property
    def total(self) -> int:
        """Devuelve el total de eventos procesados."""
        return self.uploaded + self.failed

    @property
    def success_rate(self) -> float:
        """Calcula el porcentaje de éxito."""
        if self.total == 0:
            return 0.0

        return self.uploaded / self.total * 100


def load_environment() -> None:
    """Carga variables desde .env si python-dotenv está instalado."""
    if load_dotenv is None:
        console.print(
            "[yellow]⚠️ python-dotenv no está instalado; "
            "se usarán solo variables de entorno del sistema.[/yellow]"
        )
        return

    load_dotenv()


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Define y parsea los argumentos de línea de comandos."""
    parser = argparse.ArgumentParser(
        description="Sube eventos saneados a la API EventvsMérida.",
    )
    parser.add_argument(
        "input",
        help="JSON de eventos saneados generado por saneador_caracteres.py.",
    )
    parser.add_argument(
        "--api-url",
        default=DEFAULT_API_URL,
        help="URL API para publicar eventos.",
    )
    parser.add_argument(
        "--email",
        default=os.getenv("EVENTVSMERIDA_EMAIL"),
        help="Email admin o variable EVENTVSMERIDA_EMAIL.",
    )
    parser.add_argument(
        "--password",
        default=os.getenv("EVENTVSMERIDA_PASSWORD"),
        help="Password admin o variable EVENTVSMERIDA_PASSWORD.",
    )

    return parser.parse_args(argv)


def validate_input_file(input_path: Path) -> bool:
    """Comprueba que el archivo de entrada exista."""
    if input_path.exists():
        return True

    console.print(f"[red]Archivo no encontrado:[/red] {input_path}")
    return False


def validate_credentials(email: str | None, password: str | None) -> bool:
    """Comprueba que existan credenciales de administrador."""
    if email and password:
        return True

    console.print("[red]✗ Faltan credenciales de admin (email/password).[/red]")
    return False


def load_json_auto(path: Path | str) -> Any:
    """Carga un JSON probando varias codificaciones habituales."""
    file_path = Path(path)

    for encoding in JSON_ENCODINGS:
        try:
            with file_path.open(encoding=encoding) as file:
                return json.load(file)
        except UnicodeDecodeError:
            continue
        except json.JSONDecodeError as exc:
            raise RuntimeError(
                f"Archivo leído con {encoding}, pero el JSON no es válido: {exc}"
            ) from exc

    raise RuntimeError(
        "No se pudo decodificar el archivo con las codificaciones probadas."
    )


def get_events_from_payload(data: Any) -> list[dict[str, Any]]:
    """Obtiene la lista de eventos desde el JSON de entrada."""
    if not isinstance(data, dict):
        return []

    events = data.get("events", [])

    if not isinstance(events, list):
        return []

    return [event for event in events if isinstance(event, dict)]


def build_auth_url(api_url: str) -> str:
    """Construye la URL base de autenticación desde la URL de publicación."""
    parsed_url = urlparse(api_url)
    base_url = f"{parsed_url.scheme}://{parsed_url.netloc}"

    return urljoin(base_url, "/api/auth")


def login_admin(
    session: requests.Session,
    auth_url: str,
    email: str,
    password: str,
) -> bool:
    """Inicia sesión como administrador y valida que la sesión sea correcta."""
    payload = {"email": email, "password": password}

    try:
        login_response = session.post(
            f"{auth_url}/login",
            params={"admin": "true"},
            json=payload,
            timeout=DEFAULT_HTTP_TIMEOUT_SECONDS,
        )
    except requests.RequestException as exc:
        console.print(f"[red]✗ Error conectando con login:[/red] {exc}")
        return False

    if login_response.status_code != requests.codes.ok:
        console.print(
            f"[red]✗ Login fallido[/red] "
            f"[dim](HTTP {login_response.status_code})[/dim]"
        )
        return False

    try:
        session_response = session.get(
            f"{auth_url}/session",
            timeout=DEFAULT_HTTP_TIMEOUT_SECONDS,
        )
    except requests.RequestException as exc:
        console.print(f"[red]✗ Error validando sesión:[/red] {exc}")
        return False

    if session_response.status_code != requests.codes.ok:
        console.print(
            f"[red]✗ Sesión no válida[/red] "
            f"[dim](HTTP {session_response.status_code})[/dim]"
        )
        return False

    return True


def init_geocoder() -> Any | None:
    """
    Inicializa MapsGeocoder si está disponible.

    Primero intenta importar maps_geocoder.py, que es el nombre correcto en snake_case.
    Se mantiene fallback a mapsgeocoder por compatibilidad con nombres antiguos.
    """
    try:
        try:
            from maps_geocoder import MapsGeocoder
        except ImportError:
            from mapsgeocoder import MapsGeocoder  # type: ignore[no-redef]
    except ImportError:
        console.print(
            "[yellow]⚠️ maps_geocoder no disponible; "
            "se omite geocodificación.[/yellow]"
        )
        return None

    try:
        return MapsGeocoder(
            headless=True,
            nav_timeout=DEFAULT_GEOCODER_NAV_TIMEOUT_MS,
        )
    except Exception as exc:
        console.print(
            "[yellow]⚠️ No se pudo iniciar MapsGeocoder; "
            f"se seguirá sin geocodificación:[/yellow] {exc}"
        )
        return None


def close_geocoder(geocoder: Any | None) -> None:
    """Cierra MapsGeocoder de forma segura si se ha inicializado."""
    if geocoder is None:
        return

    try:
        geocoder.close()
    except Exception:
        logger.debug("No se pudo cerrar MapsGeocoder correctamente.", exc_info=True)


def geocode_location(geocoder: Any | None, location: str) -> Coordinates | None:
    """Geocodifica una localización usando dos intentos."""
    if geocoder is None or not location:
        return None

    try:
        coords = geocoder.geocode(
            location,
            max_wait=6.0,
            poll_interval=0.25,
        )

        if coords:
            return coords

        return geocoder.geocode(
            location,
            max_wait=8.0,
            poll_interval=0.35,
        )
    except Exception as exc:
        logger.warning("Error geocodificando %s: %s", location, exc)
        return None


def print_geocoding_result(
    title: str,
    location: str,
    coords: Coordinates | None,
) -> None:
    """Muestra por consola el resultado de geocodificar un evento."""
    short_title = title[:60]

    if coords:
        latitude, longitude = coords
        console.print(
            f"    Título: {short_title} | "
            f"[green]📍 Coordenadas:[/green] {latitude}, {longitude}"
        )
        return

    if location:
        console.print(
            f"    Título: {short_title} | "
            f"[yellow]⚠️ No se pudo geocodificar:[/yellow] {location}"
        )
        return

    console.print(f"    Título: {short_title}")


def pick_largest_from_srcset(srcset: str) -> str | None:
    """Selecciona la URL con mayor anchura declarada en un atributo srcset."""
    best_url: str | None = None
    best_width = -1

    for srcset_item in (item.strip() for item in srcset.split(",")):
        if not srcset_item:
            continue

        parts = srcset_item.split()
        image_url = parts[0]
        width = extract_srcset_width(parts)

        if width > best_width:
            best_width = width
            best_url = image_url

    return best_url


def extract_srcset_width(srcset_parts: list[str]) -> int:
    """Extrae la anchura numérica de una entrada srcset."""
    if len(srcset_parts) < 2:
        return 0

    width_match = re.match(r"(\d+)w", srcset_parts[1])

    if not width_match:
        return 0

    return int(width_match.group(1))


def obtener_imagen_grande(
    event_url: str,
    session: requests.Session | None = None,
    timeout: int = DEFAULT_IMAGE_TIMEOUT_SECONDS,
) -> str | None:
    """
    Intenta obtener una imagen representativa grande desde la página del evento.

    Estrategia:
        1. Imagen dentro de un enlace.
        2. Imagen con srcset, eligiendo la de mayor tamaño.
        3. Imagen con src como fallback.
    """
    if not event_url:
        return None

    try:
        response = fetch_event_page(event_url, session, timeout)
    except requests.RequestException as exc:
        logger.debug("Error obteniendo la página del evento %s: %s", event_url, exc)
        return None

    soup = BeautifulSoup(response.text, "html.parser")
    container = soup.select_one(".tribe-events-single-event-description") or soup

    return (
        extract_linked_image_url(container, event_url)
        or extract_srcset_image_url(container, event_url)
        or extract_src_image_url(container, event_url)
    )


def fetch_event_page(
    event_url: str,
    session: requests.Session | None,
    timeout: int,
) -> requests.Response:
    """Descarga la página HTML de un evento y valida la respuesta."""
    http_client = session or requests
    response = http_client.get(
        event_url,
        headers=REQUEST_HEADERS,
        timeout=timeout,
    )
    response.raise_for_status()

    return response


def extract_linked_image_url(container: BeautifulSoup, event_url: str) -> str | None:
    """Devuelve el enlace de una imagen envuelta en un <a>, si existe."""
    image_inside_link = container.select_one("a[href] > img")

    if not image_inside_link or not image_inside_link.parent:
        return None

    if image_inside_link.parent.name != "a":
        return None

    href = image_inside_link.parent.get("href")

    return urljoin(event_url, href) if href else None


def extract_srcset_image_url(container: BeautifulSoup, event_url: str) -> str | None:
    """Selecciona la mejor imagen disponible desde un atributo srcset."""
    image = container.select_one("img[srcset]")

    if not image or not image.get("srcset"):
        return None

    image_url = pick_largest_from_srcset(image["srcset"])

    return urljoin(event_url, image_url) if image_url else None


def extract_src_image_url(container: BeautifulSoup, event_url: str) -> str | None:
    """Obtiene la imagen desde el atributo src como último recurso."""
    image = container.select_one("img[src]")

    if not image or not image.get("src"):
        return None

    return urljoin(event_url, image["src"])


def safe_int(value: Any, default: int) -> int:
    """Convierte un valor a entero devolviendo un fallback si falla."""
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def extract_category_id(event: dict[str, Any]) -> int:
    """
    Extrae el identificador de categoría desde el evento saneado.

    El saneador puede dejar la categoría normalizada dentro de raw.CATEGORIES.
    Se añade también soporte para category/categoria por si el formato cambia.
    """
    raw = event.get("raw")
    raw_categories = raw.get("CATEGORIES") if isinstance(raw, dict) else None

    if isinstance(raw_categories, dict):
        return safe_int(raw_categories.get("id"), DEFAULT_CATEGORY_ID)

    category = event.get("category") or event.get("categoria")

    if isinstance(category, dict):
        return safe_int(category.get("id"), DEFAULT_CATEGORY_ID)

    return DEFAULT_CATEGORY_ID


def build_prepared_event(
    event: dict[str, Any],
    session: requests.Session,
    geocoder: Any | None,
) -> PreparedEvent:
    """Convierte un evento saneado al formato esperado por la API."""
    title = event.get("summary", "") or ""
    location = event.get("location", "") or ""

    coords = geocode_location(geocoder, location)
    latitude, longitude = coords if coords else (None, None)

    print_geocoding_result(title, location, coords)

    return {
        "titulo": title,
        "descripcion": event.get("description", "") or "",
        "fechaInicio": event.get("dtstart", "") or "",
        "fechaFin": event.get("dtend", "") or "",
        "localizacion": location,
        "latitud": latitude,
        "longitud": longitude,
        "foto": obtener_imagen_grande(
            event_url=event.get("url", "") or "",
            session=session,
            timeout=DEFAULT_IMAGE_TIMEOUT_SECONDS,
        ),
        "idUsuario": random.choice(DEFAULT_USER_IDS),
        "idCategoria": extract_category_id(event),
    }


def prepare_events(
    events: list[dict[str, Any]],
    session: requests.Session,
    geocoder: Any | None,
) -> list[PreparedEvent]:
    """Prepara todos los eventos antes de publicarlos en la API."""
    prepared_events: list[PreparedEvent] = []

    console.print("[cyan]→[/cyan] Procesando localizaciones...\n")

    with Progress() as progress:
        task = progress.add_task("[cyan]Localizando", total=len(events))

        for event in events:
            prepared_events.append(build_prepared_event(event, session, geocoder))

            # Pequeña pausa para no saturar geocodificación ni scraping de imágenes.
            time.sleep(0.15)
            progress.update(task, advance=1)

    return prepared_events


def upload_event(
    session: requests.Session,
    api_url: str,
    event: PreparedEvent,
) -> bool:
    """Publica un evento en la API."""
    event_payload = json.dumps(event, ensure_ascii=False)

    response = session.post(
        api_url,
        data={"evento": event_payload},
        files={"imagen": ("", b"", "application/octet-stream")},
        timeout=DEFAULT_HTTP_TIMEOUT_SECONDS,
    )
    response.raise_for_status()

    return response.status_code == requests.codes.created


def upload_single_event_with_feedback(
    session: requests.Session,
    api_url: str,
    event: PreparedEvent,
) -> bool:
    """Sube un evento mostrando el resultado por consola."""
    timestamp = datetime.now().strftime("%H:%M:%S")
    short_title = (event.get("titulo") or "")[:50]

    console.print(f"[blue][{timestamp}][/blue] [bold]📌 {short_title}[/bold]")

    try:
        if upload_event(session, api_url, event):
            console.print("        [green]✓ Publicado[/green] [dim](HTTP 201)[/dim]")
            return True

        console.print("        [red]✗ Respuesta no válida[/red]")
        return False

    except requests.exceptions.HTTPError as exc:
        status_code = exc.response.status_code if exc.response is not None else "sin código"
        console.print(f"        [red]✗ Error HTTP[/red] [dim](HTTP {status_code})[/dim]")
        return False

    except requests.exceptions.Timeout:
        console.print("        [red]✗ Timeout[/red] [dim](servidor tardó demasiado)[/dim]")
        return False

    except requests.exceptions.RequestException as exc:
        console.print(f"        [red]✗ Error de conexión[/red] [dim]({str(exc)[:80]})[/dim]")
        return False


def print_upload_header() -> None:
    """Muestra el encabezado de la fase de subida."""
    console.print()
    console.print(
        Panel(
            Text("ENVIANDO EVENTOS A API", style="bold green"),
            border_style="green",
        )
    )
    console.print()


def upload_events(
    session: requests.Session,
    api_url: str,
    events: list[PreparedEvent],
) -> UploadStats:
    """Sube todos los eventos preparados y devuelve estadísticas."""
    stats = UploadStats()
    print_upload_header()

    with Progress() as progress:
        task = progress.add_task("[green]Subiendo", total=len(events))

        for event in events:
            if upload_single_event_with_feedback(session, api_url, event):
                stats.uploaded += 1
            else:
                stats.failed += 1

            progress.update(task, advance=1)

    return stats


def print_summary(stats: UploadStats) -> None:
    """Muestra una tabla resumen con los resultados finales."""
    table = Table(title="RESUMEN FINAL", border_style="cyan", show_header=True)
    table.add_column("Métrica", style="cyan")
    table.add_column("Valor", style="bold")
    table.add_row("Eventos enviados", f"[green]{stats.uploaded}[/green]/{stats.total}")
    table.add_row("Eventos fallidos", f"[red]{stats.failed}[/red]/{stats.total}")
    table.add_row("Tasa de éxito", f"[yellow]{stats.success_rate:.1f}%[/yellow]")

    console.print()
    console.print(table)
    console.print()


def main(argv: list[str] | None = None) -> int:
    """
    Lee eventos saneados, los prepara y los publica en la API.

    Returns:
        Código de salida del proceso.
    """
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    load_environment()

    args = parse_args(argv)
    input_path = Path(args.input)

    if not validate_input_file(input_path):
        return 2

    if not validate_credentials(args.email, args.password):
        return 2

    try:
        data = load_json_auto(input_path)
    except RuntimeError as exc:
        console.print(f"[red]✗ Error cargando JSON:[/red] {exc}")
        return 2

    events = get_events_from_payload(data)
    console.print(f"[green]✓[/green] Se cargaron [bold]{len(events)}[/bold] eventos\n")

    geocoder = init_geocoder()

    try:
        with requests.Session() as session:
            session.headers.update(REQUEST_HEADERS)

            auth_url = build_auth_url(args.api_url)

            if not login_admin(session, auth_url, args.email, args.password):
                return 2

            prepared_events = prepare_events(events, session, geocoder)
            stats = upload_events(session, args.api_url, prepared_events)

    finally:
        close_geocoder(geocoder)

    print_summary(stats)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
