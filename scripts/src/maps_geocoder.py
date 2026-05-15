"""
Módulo para geocodificar ubicaciones usando Google Maps mediante Playwright.

Este archivo permite buscar una localización en Google Maps, navegar con un navegador
automatizado y extraer coordenadas geográficas a partir de la URL o del HTML resultante.

Requisitos:
    pip install playwright
    python -m playwright install chromium

@author Eva Retamar
@author David Muñoz
@author Adrián Pérez
"""

import logging
import re
import time
from pathlib import Path
from typing import Any, Pattern
from urllib.parse import parse_qs, quote_plus, unquote, urlparse

from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
from playwright.sync_api import sync_playwright


logger = logging.getLogger(__name__)

Coordinate = tuple[float, float]


class MapsGeocoder:
    """Geocodificador de ubicaciones en Google Maps usando Playwright."""

    DEFAULT_MERIDA: Coordinate = (38.918017, -6.342947)
    DEFAULT_NAV_TIMEOUT_MS: int = 8_000
    DEFAULT_GOTO_TIMEOUT_MS: int = 5_000
    DEFAULT_CONSENT_TIMEOUT_MS: int = 3_000
    DEFAULT_MAX_WAIT_SECONDS: float = 4.0
    DEFAULT_POLL_INTERVAL_SECONDS: float = 0.2
    PAGE_SNIPPET_MAX_CHARS: int = 2_000

    DEFAULT_USER_AGENT: str = (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/116.0 Safari/537.36"
    )

    BROWSER_ARGS: list[str] = [
        "--no-sandbox",
        "--disable-dev-shm-usage",
    ]

    CONSENT_COOKIE: dict[str, str] = {
        "name": "CONSENT",
        "value": "YES+1",
        "domain": ".google.com",
        "path": "/",
    }

    CONSENT_SELECTORS: tuple[str, ...] = (
        "#introAgreeButton",
        "button:has-text('Aceptar')",
        "button:has-text('Acepto')",
        "button:has-text('Aceptar todo')",
        "button:has-text('Agree')",
        "a:has-text('Aceptar')",
    )

    COORD_PATTERNS: tuple[Pattern[str], ...] = tuple(
        re.compile(pattern, re.S)
        for pattern in (
            r"@(-?\d+\.\d+),(-?\d+\.\d+)",
            r"!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)",
            r"center=(-?\d+\.\d+),(-?\d+\.\d+)",
            r'"lat"\s*:\s*([0-9.\-]+).*?"lng"\s*:\s*([0-9.\-]+)',
        )
    )

    def __init__(
        self,
        headless: bool = True,
        nav_timeout: int = DEFAULT_NAV_TIMEOUT_MS,
        user_agent: str | None = None,
    ) -> None:
        """
        Inicializa Playwright, el navegador, el contexto y una página nueva.

        Args:
            headless: Indica si el navegador se ejecuta en modo oculto.
            nav_timeout: Tiempo máximo por defecto para navegación y esperas, en ms.
            user_agent: User-Agent personalizado. Si no se indica, usa uno por defecto.
        """
        self.playwright = sync_playwright().start()
        self.browser = self.playwright.chromium.launch(
            headless=headless,
            args=self.BROWSER_ARGS,
        )
        self.context = self.browser.new_context(
            user_agent=user_agent or self.DEFAULT_USER_AGENT,
        )

        self._add_consent_cookie()

        self.page = self.context.new_page()
        self.page.set_default_navigation_timeout(nav_timeout)
        self.page.set_default_timeout(nav_timeout)

    def _add_consent_cookie(self) -> None:
        """Añade una cookie de consentimiento para reducir popups de Google."""
        try:
            self.context.add_cookies([self.CONSENT_COOKIE])
        except Exception:
            logger.debug("No se pudo añadir la cookie CONSENT.", exc_info=True)

    def _goto(
        self,
        url: str,
        wait_until: str = "domcontentloaded",
        timeout: int = DEFAULT_GOTO_TIMEOUT_MS,
    ) -> bool:
        """
        Navega a una URL controlando posibles errores de Playwright.

        Args:
            url: URL de destino.
            wait_until: Evento que debe esperar Playwright antes de continuar.
            timeout: Tiempo máximo de navegación, en ms.

        Returns:
            True si la navegación se completa sin errores, False en caso contrario.
        """
        try:
            self.page.goto(url, wait_until=wait_until, timeout=timeout)
            return True
        except PlaywrightTimeoutError:
            logger.debug("Timeout al navegar a %s", url, exc_info=True)
        except Exception:
            logger.debug("Error al navegar a %s", url, exc_info=True)

        return False

    def _handle_consent(self, url: str) -> bool:
        """
        Intenta resolver la pantalla de consentimiento de Google si aparece.

        Args:
            url: URL actual de la página.

        Returns:
            True si se ha realizado alguna acción de consentimiento.
        """
        if "consent.google.com" not in url:
            return False

        return self._click_consent_button() or self._follow_consent_continue_url(url)

    def _click_consent_button(self) -> bool:
        """
        Busca y pulsa uno de los botones conocidos de consentimiento.

        Returns:
            True si se ha pulsado algún botón.
        """
        for selector in self.CONSENT_SELECTORS:
            try:
                locator = self.page.locator(selector)

                if locator.count() > 0:
                    locator.first.click(timeout=1_000)
                    time.sleep(0.25)
                    logger.debug("Pulsado selector de consentimiento: %s", selector)
                    return True

            except Exception:
                logger.debug(
                    "Falló el click del selector de consentimiento: %s",
                    selector,
                    exc_info=True,
                )

        return False

    def _follow_consent_continue_url(self, url: str) -> bool:
        """
        Sigue la URL de continuación incluida en la pantalla de consentimiento.

        Args:
            url: URL actual de consentimiento.

        Returns:
            True si se ha encontrado la URL de continuación y la navegación no ha fallado.
        """
        continue_url = self._extract_continue_url(url)

        if not continue_url:
            return False

        logger.debug("Siguiendo URL de continuación: %s", continue_url)

        return self._goto(
            continue_url,
            timeout=self.DEFAULT_CONSENT_TIMEOUT_MS,
        )

    @staticmethod
    def _extract_continue_url(url: str) -> str | None:
        """
        Extrae una URL de continuación desde los parámetros de query.

        Args:
            url: URL desde la que se quiere obtener el parámetro de continuación.

        Returns:
            URL decodificada si existe, None en caso contrario.
        """
        parsed_url = urlparse(url)
        query_params = parse_qs(parsed_url.query)

        for param_name in ("continue", "continue_url", "dest", "url"):
            values = query_params.get(param_name)

            if values:
                return unquote(values[0])

        return None

    def _extract_coords_from_text(self, text: str) -> Coordinate | None:
        """
        Extrae coordenadas desde un texto usando patrones conocidos de Google Maps.

        Args:
            text: URL o HTML donde buscar coordenadas.

        Returns:
            Tupla con latitud y longitud si se encuentran coordenadas.
        """
        for pattern in self.COORD_PATTERNS:
            match = pattern.search(text)

            if not match:
                continue

            try:
                return float(match.group(1)), float(match.group(2))
            except ValueError:
                logger.debug(
                    "No se pudieron convertir coordenadas a float.",
                    exc_info=True,
                )

        return None

    def _save_debug(self, location: str, html: str) -> None:
        """
        Guarda una captura de pantalla y el HTML actual para depuración.

        Args:
            location: Texto de búsqueda usado para generar el nombre del archivo.
            html: HTML que se guardará en disco.
        """
        try:
            safe_location = self._sanitize_filename(location)
            timestamp = time.strftime("%Y%m%d-%H%M%S")

            screenshot_path = Path(
                f"maps_debug_{safe_location}_{timestamp}.png"
            ).resolve()
            html_path = Path(
                f"maps_debug_{safe_location}_{timestamp}.html"
            ).resolve()

            self.page.screenshot(path=str(screenshot_path), full_page=True)
            html_path.write_text(html, encoding="utf-8")

            logger.debug(
                "Archivos de debug guardados: %s %s",
                screenshot_path,
                html_path,
            )
        except Exception:
            logger.debug("Falló el guardado de archivos de depuración.", exc_info=True)

    @staticmethod
    def _sanitize_filename(value: str, max_length: int = 50) -> str:
        """
        Limpia un texto para poder usarlo como parte de un nombre de archivo.

        Args:
            value: Texto original.
            max_length: Longitud máxima del resultado.

        Returns:
            Texto seguro para usar en nombres de archivo.
        """
        return re.sub(r"[^A-Za-z0-9_.-]", "_", value)[:max_length]

    def geocode(
        self,
        location: str,
        max_wait: float = DEFAULT_MAX_WAIT_SECONDS,
        poll_interval: float = DEFAULT_POLL_INTERVAL_SECONDS,
        debug: bool = False,
    ) -> Coordinate | None:
        """
        Geocodifica una localización usando Google Maps.

        Args:
            location: Texto de la localización a geocodificar.
            max_wait: Tiempo máximo de espera, en segundos.
            poll_interval: Intervalo entre comprobaciones, en segundos.
            debug: Si es True, guarda captura y HTML cuando no encuentra coordenadas.

        Returns:
            Tupla con latitud y longitud si se encuentra, None en caso contrario.
        """
        if not self._is_valid_location(location):
            return None

        if self._is_generic_city_points_location(location):
            return self.DEFAULT_MERIDA

        search_url = self._build_search_url(location)
        logger.debug("Iniciando geocodificación: %s -> %s", location, search_url)

        try:
            if not self._goto(search_url):
                return None

            coords = self._poll_coordinates(max_wait, poll_interval)

            if coords:
                return coords

            return self._extract_final_coordinates(location, debug)

        except Exception as exc:
            logger.exception("Error durante la geocodificación: %s", exc)
            return None

    @staticmethod
    def _is_valid_location(location: str) -> bool:
        """
        Comprueba si una localización tiene contenido útil.

        Args:
            location: Localización a validar.

        Returns:
            True si la localización no está vacía.
        """
        return bool(location and location.strip())

    @staticmethod
    def _is_generic_city_points_location(location: str) -> bool:
        """
        Detecta el caso especial 'varios puntos de la ciudad'.

        Args:
            location: Localización introducida.

        Returns:
            True si coincide con el caso especial.
        """
        return "varios puntos de la ciudad" in location.strip().lower()

    @staticmethod
    def _build_search_url(location: str) -> str:
        """
        Construye la URL de búsqueda de Google Maps.

        Args:
            location: Texto de búsqueda.

        Returns:
            URL preparada para navegar a Google Maps.
        """
        encoded_location = quote_plus(location)
        return f"https://www.google.com/maps/search/?api=1&query={encoded_location}"

    def _poll_coordinates(
        self,
        max_wait: float,
        poll_interval: float,
    ) -> Coordinate | None:
        """
        Busca coordenadas durante un tiempo limitado revisando URL y HTML parcial.

        Args:
            max_wait: Tiempo máximo total de espera, en segundos.
            poll_interval: Pausa entre intentos, en segundos.

        Returns:
            Coordenadas si se encuentran durante el polling.
        """
        deadline = time.time() + max_wait
        previous_url: str | None = None

        while time.time() < deadline:
            current_url = self.page.url

            if current_url != previous_url:
                logger.debug("URL actual durante polling: %s", current_url)
                previous_url = current_url

            if self._handle_consent(current_url):
                time.sleep(0.25)
                continue

            coords = self._extract_coords_from_text(current_url)

            if coords:
                logger.debug("Coordenadas extraídas desde URL: %s", coords)
                return coords

            coords = self._extract_coords_from_page_snippet()

            if coords:
                logger.debug("Coordenadas extraídas desde HTML parcial: %s", coords)
                return coords

            time.sleep(poll_interval)

        return None

    def _extract_coords_from_page_snippet(self) -> Coordinate | None:
        """
        Extrae coordenadas desde un fragmento inicial del HTML de la página.

        Returns:
            Coordenadas si se encuentran.
        """
        try:
            snippet = self.page.content()[: self.PAGE_SNIPPET_MAX_CHARS]
            return self._extract_coords_from_text(snippet)
        except Exception:
            logger.debug("Falló la lectura parcial del contenido HTML.", exc_info=True)
            return None

    def _extract_final_coordinates(
        self,
        location: str,
        debug: bool,
    ) -> Coordinate | None:
        """
        Realiza una última extracción de coordenadas desde la URL y el HTML final.

        Args:
            location: Localización original, usada para nombrar archivos de debug.
            debug: Si es True, guarda archivos de depuración si no encuentra coordenadas.

        Returns:
            Coordenadas si se encuentran, None en caso contrario.
        """
        final_url = self.page.url
        html = self.page.content()

        logger.debug("URL final tras espera: %s", final_url)

        coords = (
            self._extract_coords_from_text(final_url)
            or self._extract_coords_from_text(html)
        )

        if coords:
            logger.debug("Coordenadas extraídas en el parseo final: %s", coords)
            return coords

        if debug:
            self._save_debug(location, html)

        return None

    def close(self) -> None:
        """Cierra contexto, navegador y Playwright de forma segura."""
        self._safe_close(self.context, "contexto")
        self._safe_close(self.browser, "navegador")
        self._safe_close(self.playwright, "playwright", stop=True)

    @staticmethod
    def _safe_close(resource: Any, resource_name: str, stop: bool = False) -> None:
        """
        Cierra o detiene un recurso ignorando errores de limpieza.

        Args:
            resource: Recurso a cerrar.
            resource_name: Nombre descriptivo para los logs.
            stop: Si es True, usa stop() en lugar de close().
        """
        try:
            if stop:
                resource.stop()
            else:
                resource.close()
        except Exception:
            logger.debug(
                "No se pudo cerrar %s correctamente.",
                resource_name,
                exc_info=True,
            )

    def __enter__(self) -> "MapsGeocoder":
        """Permite usar la clase con un context manager."""
        return self

    def __exit__(
        self,
        _exc_type: type[BaseException] | None,
        _exc_value: BaseException | None,
        _traceback: Any,
    ) -> None:
        """Cierra recursos automáticamente al salir del context manager."""
        self.close()
