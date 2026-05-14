"""
Sanea y normaliza un archivo JSON de eventos.

Este script limpia textos, normaliza fechas en formato ISO sin zona horaria y convierte
categorías en una estructura estándar con identificador y nombre.

Uso:
    python src/saneador_caracteres.py data/raw/eventos_bruto.json data/processed/eventos_saneados.json

@author Eva Retamar
@author David Muñoz
@author Adrián Pérez
"""

import json
import re
import sys
import unicodedata
from datetime import datetime
from pathlib import Path
from typing import Any


WHITESPACE_REGEX = re.compile(r"[ \t]+")
DATE_ONLY_REGEX = re.compile(r"\d{4}-\d{2}-\d{2}")
CATEGORY_ID_REGEX = re.compile(r"\b([1-9]|1[0-2])\b")

DEFAULT_CATEGORY_ID = 12
DATE_KEYS = {"dtstart", "dtend"}
SKIP_SANITIZE_KEYS = {"fetched_at"}

CATEGORY_CHOICES: dict[int, str] = {
    1: "Conciertos y Música",
    2: "Festivales y Ferias",
    3: "Cine y Teatro",
    4: "Exposiciones y Arte",
    5: "Gastronomía",
    6: "Conferencias, Talleres y Cursos",
    7: "Deportes y Actividad Física",
    8: "Fiestas y Vida Nocturna",
    9: "Familia e Infantil",
    10: "Tecnología y Ciencia",
    11: "Solidaridad y Causas Sociales",
    12: "Otros",
}

KEYWORD_TO_CATEGORY_ID: dict[str, int] = {
    "concierto": 1,
    "conciertos": 1,
    "musica": 1,
    "musical": 1,
    "jazz": 1,
    "orquesta": 1,
    "festival": 2,
    "feria": 2,
    "festivales": 2,
    "ferias": 2,
    "semana santa": 2,
    "comercio": 2,
    "convivencia": 2,
    "recreacion": 2,
    "emerita lvdica": 2,
    "cine": 3,
    "teatro": 3,
    "pelicula": 3,
    "peliculas": 3,
    "obra": 3,
    "danza": 3,
    "exposicion": 4,
    "exposiciones": 4,
    "arte": 4,
    "galeria": 4,
    "museo": 4,
    "gastronomia": 5,
    "gastronomica": 5,
    "comida": 5,
    "degustacion": 5,
    "conferencia": 6,
    "taller": 6,
    "talleres": 6,
    "curso": 6,
    "cursos": 6,
    "charla": 6,
    "congreso": 6,
    "educacion": 6,
    "literatura": 6,
    "deporte": 7,
    "deportes": 7,
    "actividad fisica": 7,
    "carrera": 7,
    "maraton": 7,
    "partido": 7,
    "fiesta": 8,
    "fiestas": 8,
    "noche": 8,
    "nocturna": 8,
    "verben": 8,
    "familia": 9,
    "infantil": 9,
    "ninos": 9,
    "nino": 9,
    "cuentacuentos": 9,
    "tecnologia": 10,
    "ciencia": 10,
    "robotica": 10,
    "solidaridad": 11,
    "solidario": 11,
    "benefico": 11,
    "otros": 12,
    "otro": 12,
    "varios": 12,
}

CATEGORY_KEYS = {
    "category",
    "categoria",
    "category_name",
    "categoryname",
    "tipo",
    "tags",
    "categories",
    "categorias",
    "etiquetas",
    "categoria_nombre",
    "category-name",
}

CATEGORY_NAME_KEYS = (
    "name",
    "nombre",
    "title",
    "category",
    "categoria",
)


def sanitize_text(value: str) -> str:
    """
    Limpia escapes comunes y espacios sobrantes en un texto.

    Args:
        value: Texto original.

    Returns:
        Texto limpio y normalizado.
    """
    value = value.replace("\\n", " ")
    value = value.replace("\\,", ",")
    value = value.replace("\\\\", "\\")
    value = value.replace("\\", "")

    return WHITESPACE_REGEX.sub(" ", value).strip()


def to_iso_without_timezone(value: str) -> str:
    """
    Normaliza una fecha ISO eliminando la zona horaria si existe.

    Args:
        value: Fecha en formato ISO o fecha simple YYYY-MM-DD.

    Returns:
        Fecha con formato YYYY-MM-DDTHH:MM:SS.

    Raises:
        ValueError: Si el formato de fecha no es soportado.
    """
    clean_value = value.strip()

    if DATE_ONLY_REGEX.fullmatch(clean_value):
        return f"{clean_value}T00:00:00"

    normalized_value = (
        clean_value.replace("Z", "+00:00")
        if clean_value.endswith("Z")
        else clean_value
    )

    try:
        date_value = datetime.fromisoformat(normalized_value)
    except ValueError as exc:
        raise ValueError(
            f"Formato de fecha/hora no soportado: {value!r}"
        ) from exc

    # Se elimina la zona horaria para mantener el formato requerido por el JSON final.
    date_without_timezone = date_value.replace(tzinfo=None)

    return date_without_timezone.strftime("%Y-%m-%dT%H:%M:%S")


def strip_accents(value: str) -> str:
    """
    Elimina acentos y marcas diacríticas de un texto.

    Args:
        value: Texto original.

    Returns:
        Texto sin acentos.
    """
    return "".join(
        char
        for char in unicodedata.normalize("NFKD", value)
        if not unicodedata.combining(char)
    )


def normalize_text_for_matching(value: str) -> str:
    """
    Prepara un texto para comparaciones por palabra clave.

    Args:
        value: Texto original.

    Returns:
        Texto en minúsculas, sin acentos ni símbolos innecesarios.
    """
    normalized = sanitize_text(value).lower()
    normalized = strip_accents(normalized)
    normalized = re.sub(r"[/_-]+", " ", normalized)
    normalized = re.sub(r"[^a-z0-9 ]+", " ", normalized)

    return re.sub(r"\s+", " ", normalized).strip()


def build_category(category_id: int) -> dict[str, Any]:
    """
    Construye una categoría con el formato estándar.

    Args:
        category_id: Identificador de categoría.

    Returns:
        Diccionario con id y nombre de categoría.
    """
    safe_category_id = (
        category_id
        if category_id in CATEGORY_CHOICES
        else DEFAULT_CATEGORY_ID
    )

    return {
        "id": safe_category_id,
        "nombre": CATEGORY_CHOICES[safe_category_id],
    }


def normalize_category(value: str) -> dict[str, Any]:
    """
    Normaliza una categoría al formato {'id': int, 'nombre': str}.

    Args:
        value: Texto de categoría.

    Returns:
        Categoría normalizada.
    """
    if not value or not value.strip():
        return build_category(DEFAULT_CATEGORY_ID)

    normalized_value = normalize_text_for_matching(value)

    for keyword, category_id in KEYWORD_TO_CATEGORY_ID.items():
        if keyword in normalized_value:
            return build_category(category_id)

    category_id_match = CATEGORY_ID_REGEX.search(normalized_value)

    if category_id_match:
        return build_category(int(category_id_match.group(1)))

    return build_category(DEFAULT_CATEGORY_ID)


def extract_category_text(value: Any) -> str:
    """
    Extrae un texto de categoría desde strings, listas o diccionarios.

    Args:
        value: Valor original de la categoría.

    Returns:
        Texto candidato para normalizar. Si no encuentra uno claro, devuelve cadena vacía.
    """
    if isinstance(value, str):
        return value

    if isinstance(value, dict):
        return extract_category_text_from_dict(value)

    if isinstance(value, list):
        for item in value:
            category_text = extract_category_text(item)

            if category_text:
                return category_text

        # Si la lista no contiene un texto claro, se usa su representación como último recurso.
        return " ".join(str(item) for item in value)

    return ""


def extract_category_text_from_dict(value: dict[str, Any]) -> str:
    """
    Busca texto de categoría dentro de las claves habituales de un diccionario.

    Args:
        value: Diccionario con información de categoría.

    Returns:
        Texto de categoría si existe, cadena vacía en caso contrario.
    """
    for name_key in CATEGORY_NAME_KEYS:
        candidate = value.get(name_key)

        if isinstance(candidate, str) and candidate.strip():
            return candidate

    return ""


def walk_and_sanitize(
    obj: Any,
    *,
    skip_keys: set[str] | None = None,
) -> Any:
    """
    Recorre recursivamente un objeto JSON y sanea sus valores.

    Args:
        obj: Objeto JSON a procesar.
        skip_keys: Claves que no deben modificarse.

    Returns:
        Objeto saneado.
    """
    skip_keys = skip_keys or set()

    if isinstance(obj, dict):
        return sanitize_dict(obj, skip_keys)

    if isinstance(obj, list):
        return [walk_and_sanitize(item, skip_keys=skip_keys) for item in obj]

    if isinstance(obj, str):
        return sanitize_text(obj)

    return obj


def sanitize_dict(data: dict[str, Any], skip_keys: set[str]) -> dict[str, Any]:
    """
    Sanea un diccionario respetando claves especiales como fechas y categorías.

    Args:
        data: Diccionario original.
        skip_keys: Claves que se deben dejar intactas.

    Returns:
        Diccionario saneado.
    """
    sanitized: dict[str, Any] = {}

    for key, value in data.items():
        if key in skip_keys:
            sanitized[key] = value
            continue

        key_lower = key.lower()

        if key_lower in DATE_KEYS and isinstance(value, str):
            sanitized[key] = to_iso_without_timezone(value)
            continue

        if key_lower in CATEGORY_KEYS:
            category_text = extract_category_text(value)
            sanitized[key] = normalize_category(category_text)
            continue

        sanitized[key] = walk_and_sanitize(value, skip_keys=skip_keys)

    return sanitized


def load_json_file(file_path: Path) -> Any:
    """
    Carga un archivo JSON desde disco.

    Args:
        file_path: Ruta del archivo JSON.

    Returns:
        Contenido del JSON.
    """
    with file_path.open("r", encoding="utf-8") as file:
        return json.load(file)


def save_json_file(file_path: Path, data: Any) -> None:
    """
    Guarda datos en un archivo JSON con formato legible.

    Si el directorio de salida no existe, lo crea automáticamente.

    Args:
        file_path: Ruta del archivo de salida.
        data: Datos que se van a guardar.
    """
    file_path.parent.mkdir(parents=True, exist_ok=True)

    with file_path.open("w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=2)


def parse_args(args: list[str]) -> tuple[Path, Path] | None:
    """
    Valida los argumentos de entrada del script.

    Args:
        args: Argumentos recibidos por línea de comandos.

    Returns:
        Tupla con ruta de entrada y salida, o None si los argumentos no son válidos.
    """
    if len(args) != 3:
        print(
            "Uso: python src/saneador_caracteres.py "
            "data/raw/eventos_bruto.json "
            "data/processed/eventos_saneados.json",
            file=sys.stderr,
        )
        return None

    return Path(args[1]), Path(args[2])


def main() -> int:
    """
    Lee un JSON, sanea su contenido y escribe el resultado en otro archivo.

    Returns:
        Código de salida del proceso.
    """
    parsed_args = parse_args(sys.argv)

    if parsed_args is None:
        return 2

    input_path, output_path = parsed_args

    data = load_json_file(input_path)
    sanitized_data = walk_and_sanitize(data, skip_keys=SKIP_SANITIZE_KEYS)
    save_json_file(output_path, sanitized_data)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
