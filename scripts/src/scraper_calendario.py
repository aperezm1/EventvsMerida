"""
Descarga un feed iCal (ICS) y lo convierte a JSON.

Este script obtiene un calendario en formato .ics, parsea sus eventos VEVENT,
normaliza sus fechas a formato ISO y exporta el resultado a un archivo JSON.

El calendario suele exponer iCal en URLs como:
    https://TU_DOMINIO/events/?ical=1
    https://TU_DOMINIO/events/list/?ical=1

Requisitos:
    pip install requests

Uso:
    python src/scraper_calendario.py --ics-url "https://TU_DOMINIO/events/?ical=1" --out data/raw/eventos_bruto.json

Ejemplo:
    python src/scraper_calendario.py --ics-url "https://merida.es/agenda/lista/?tribe-bar-date=2026-02-01&ical=1" --out data/raw/eventos_bruto.json

@author Eva Retamar
@author David Muñoz
@author Adrián Pérez
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

import requests


DEFAULT_OUTPUT_FILE = "data/raw/eventos_bruto.json"
DEFAULT_TIMEOUT_SECONDS = 30

DEFAULT_HEADERS = {
    "User-Agent": "CalendarICSFetcher/1.0",
    "Accept": "text/calendar, text/plain, */*",
}

ICAL_DATE_REGEX = re.compile(r"\d{8}")
ICAL_DATETIME_REGEX = re.compile(r"\d{8}T\d{6}")


@dataclass
class ParsedDate:
    """Representa una fecha iCal ya interpretada."""

    value: datetime | None
    timezone: str | None
    is_all_day: bool = False


@dataclass
class Event:
    """Representa un evento del calendario ya normalizado."""

    uid: str | None
    summary: str | None
    description: str | None
    location: str | None
    url: str | None
    dtstart: str | None
    dtend: str | None
    timezone: str | None
    raw: dict[str, str]  # Campos parseados del VEVENT útiles para depurar.


def resolve_timezone(tzid: str | None) -> ZoneInfo | None:
    """
    Resuelve un identificador de zona horaria iCal a ZoneInfo.

    Args:
        tzid: Identificador de zona horaria, por ejemplo Europe/Madrid.

    Returns:
        Objeto ZoneInfo si existe, None en caso contrario.
    """
    if not tzid:
        return None

    try:
        return ZoneInfo(tzid)
    except ZoneInfoNotFoundError:
        return None


def unfold_ical_lines(text: str) -> list[str]:
    """
    Une líneas plegadas del formato iCal.

    En iCal, una línea que empieza por espacio o tabulación continúa la línea anterior.

    Args:
        text: Contenido completo del archivo ICS.

    Returns:
        Lista de líneas iCal normalizadas.
    """
    normalized_text = text.replace("\r\n", "\n").replace("\r", "\n")
    lines = normalized_text.split("\n")

    unfolded_lines: list[str] = []

    for line in lines:
        if line.startswith((" ", "\t")) and unfolded_lines:
            unfolded_lines[-1] += line[1:]
        else:
            unfolded_lines.append(line)

    return unfolded_lines


def decode_ical_text(value: str) -> str:
    """
    Decodifica escapes habituales en textos iCal.

    Args:
        value: Texto original del campo iCal.

    Returns:
        Texto limpio para usar en JSON.
    """
    return (
        value.replace("\\n", "\n")
        .replace("\\N", "\n")
        .replace("\\,", ",")
        .replace("\\;", ";")
        .replace("\\\\", "\\")
        .strip()
    )


def split_ical_property(line: str) -> tuple[str, dict[str, str], str] | None:
    """
    Divide una línea iCal en clave, parámetros y valor.

    Ejemplo:
        DTSTART;TZID=Europe/Madrid:20260201T120000

    Args:
        line: Línea iCal.

    Returns:
        Tupla con clave, parámetros y valor, o None si la línea no es válida.
    """
    if ":" not in line:
        return None

    left_part, value = line.split(":", 1)
    parts = left_part.split(";")

    key = parts[0].strip().upper()
    params: dict[str, str] = {}

    for param in parts[1:]:
        if "=" not in param:
            continue

        param_key, param_value = param.split("=", 1)
        params[param_key.strip().upper()] = param_value.strip().strip('"')

    return key, params, value.strip()


def parse_ical_datetime(
    value: str,
    params: dict[str, str],
    default_timezone: str | None,
) -> ParsedDate:
    """
    Convierte una fecha iCal a datetime.

    Soporta:
        - Fechas de día completo: YYYYMMDD
        - Fechas UTC: YYYYMMDDTHHMMSSZ
        - Fechas locales: YYYYMMDDTHHMMSS

    Args:
        value: Valor de fecha del ICS.
        params: Parámetros asociados al campo, por ejemplo TZID.
        default_timezone: Zona horaria global del calendario.

    Returns:
        Fecha parseada con metadatos de zona horaria.
    """
    clean_value = value.strip()
    timezone_id = params.get("TZID") or default_timezone

    if params.get("VALUE") == "DATE" or ICAL_DATE_REGEX.fullmatch(clean_value):
        date_value = datetime.strptime(clean_value, "%Y%m%d")
        return ParsedDate(date_value, timezone_id, is_all_day=True)

    if clean_value.endswith("Z"):
        date_value = datetime.strptime(clean_value, "%Y%m%dT%H%M%SZ")
        return ParsedDate(date_value.replace(tzinfo=timezone.utc), "UTC")

    if ICAL_DATETIME_REGEX.fullmatch(clean_value):
        date_value = datetime.strptime(clean_value, "%Y%m%dT%H%M%S")
        timezone_info = resolve_timezone(timezone_id)

        if timezone_info:
            date_value = date_value.replace(tzinfo=timezone_info)

        return ParsedDate(date_value, timezone_id)

    return ParsedDate(None, timezone_id)


def date_to_iso(parsed_date: ParsedDate) -> str | None:
    """
    Convierte una fecha parseada al formato esperado en el JSON.

    Args:
        parsed_date: Fecha iCal parseada.

    Returns:
        Fecha como YYYY-MM-DD si es de día completo o YYYY-MM-DDTHH:MM:SS si tiene hora.
    """
    if parsed_date.value is None:
        return None

    if parsed_date.is_all_day:
        return parsed_date.value.strftime("%Y-%m-%d")

    # Se elimina la zona horaria para mantener un formato sin offset.
    date_without_timezone = parsed_date.value.replace(tzinfo=None)

    return date_without_timezone.strftime("%Y-%m-%dT%H:%M:%S")


def build_event(
    raw_fields: dict[str, str],
    field_params: dict[str, dict[str, str]],
    calendar_timezone: str | None,
) -> Event:
    """
    Construye un Event normalizado a partir de los campos raw de un VEVENT.

    Args:
        raw_fields: Campos parseados del evento.
        field_params: Parámetros asociados a cada campo.
        calendar_timezone: Zona horaria global del calendario.

    Returns:
        Evento normalizado.
    """
    parsed_dtstart = parse_ical_datetime(
        raw_fields.get("DTSTART", ""),
        field_params.get("DTSTART", {}),
        calendar_timezone,
    )
    parsed_dtend = parse_ical_datetime(
        raw_fields.get("DTEND", ""),
        field_params.get("DTEND", {}),
        calendar_timezone,
    )

    timezone_used = parsed_dtstart.timezone or parsed_dtend.timezone

    return Event(
        uid=raw_fields.get("UID"),
        summary=raw_fields.get("SUMMARY"),
        description=raw_fields.get("DESCRIPTION"),
        location=raw_fields.get("LOCATION"),
        url=raw_fields.get("URL"),
        dtstart=date_to_iso(parsed_dtstart),
        dtend=date_to_iso(parsed_dtend),
        timezone=timezone_used,
        raw=dict(raw_fields),
    )


def parse_ics(text: str) -> list[Event]:
    """
    Parsea un contenido ICS y extrae sus eventos.

    Args:
        text: Contenido completo del archivo ICS.

    Returns:
        Lista de eventos normalizados.
    """
    lines = unfold_ical_lines(text)

    events: list[Event] = []
    current_fields: dict[str, str] = {}
    current_params: dict[str, dict[str, str]] = {}

    calendar_timezone: str | None = None
    inside_event = False

    for line in lines:
        if line == "BEGIN:VEVENT":
            inside_event = True
            current_fields = {}
            current_params = {}
            continue

        if line == "END:VEVENT":
            if inside_event:
                events.append(
                    build_event(
                        current_fields,
                        current_params,
                        calendar_timezone,
                    )
                )

            inside_event = False
            continue

        if not inside_event:
            calendar_timezone = extract_calendar_timezone(line, calendar_timezone)
            continue

        parsed_property = split_ical_property(line)

        if parsed_property is None:
            continue

        key, params, value = parsed_property
        current_fields[key] = decode_ical_text(value)

        if params:
            current_params[key] = params

    return events


def extract_calendar_timezone(
    line: str,
    current_timezone: str | None,
) -> str | None:
    """
    Extrae la zona horaria global del calendario si está definida.

    Args:
        line: Línea del ICS.
        current_timezone: Zona horaria detectada previamente.

    Returns:
        Nueva zona horaria detectada o la anterior si la línea no aplica.
    """
    if line.startswith("X-WR-TIMEZONE:"):
        timezone_value = line.split(":", 1)[1].strip()
        return timezone_value or None

    return current_timezone


def fetch_ics_content(ics_url: str, timeout: int) -> str:
    """
    Descarga el contenido ICS desde una URL.

    Args:
        ics_url: URL del calendario iCal.
        timeout: Tiempo máximo de espera de la petición, en segundos.

    Returns:
        Contenido del archivo ICS como texto.

    Raises:
        requests.HTTPError: Si la respuesta HTTP no es correcta.
        requests.RequestException: Si falla la conexión.
    """
    response = requests.get(
        ics_url,
        headers=DEFAULT_HEADERS,
        timeout=timeout,
    )
    response.raise_for_status()

    # utf-8-sig elimina el BOM si el servidor lo añade al principio.
    return response.content.decode("utf-8-sig", errors="replace")


def build_output_payload(ics_url: str, events: list[Event]) -> dict[str, Any]:
    """
    Construye la estructura final que se guardará en JSON.

    Args:
        ics_url: URL origen del calendario.
        events: Lista de eventos extraídos.

    Returns:
        Diccionario listo para exportarse a JSON.
    """
    return {
        "source": ics_url,
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "count": len(events),
        "events": [asdict(event) for event in events],
    }


def save_json_file(file_path: Path, data: dict[str, Any]) -> None:
    """
    Guarda un diccionario en un archivo JSON.

    Si el directorio de salida no existe, lo crea automáticamente.

    Args:
        file_path: Ruta del archivo de salida.
        data: Datos que se van a guardar.
    """
    file_path.parent.mkdir(parents=True, exist_ok=True)

    with file_path.open("w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=2)


def parse_args() -> argparse.Namespace:
    """
    Define y parsea los argumentos de línea de comandos.

    Returns:
        Argumentos parseados.
    """
    parser = argparse.ArgumentParser(
        description="Descarga un feed iCal/ICS y lo convierte a JSON.",
    )
    parser.add_argument(
        "--ics-url",
        required=True,
        help="URL del calendario iCal. Ej: https://tu-dominio.com/events/?ical=1",
    )
    parser.add_argument(
        "--out",
        default=DEFAULT_OUTPUT_FILE,
        help=f"Archivo JSON de salida. Por defecto: {DEFAULT_OUTPUT_FILE}",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=DEFAULT_TIMEOUT_SECONDS,
        help=f"Timeout de la petición en segundos. Por defecto: {DEFAULT_TIMEOUT_SECONDS}",
    )

    return parser.parse_args()


def main() -> int:
    """
    Descarga un calendario ICS, parsea sus eventos y los guarda en JSON.

    Returns:
        Código de salida del proceso.
    """
    args = parse_args()

    try:
        ics_text = fetch_ics_content(args.ics_url, args.timeout)
        events = parse_ics(ics_text)
        payload = build_output_payload(args.ics_url, events)

        output_path = Path(args.out)
        save_json_file(output_path, payload)

        print(f"OK: {output_path} ({len(events)} eventos)")
        return 0

    except requests.RequestException as exc:
        print(f"Error al descargar el calendario ICS: {exc}")
        return 1

    except OSError as exc:
        print(f"Error al escribir el archivo de salida: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
