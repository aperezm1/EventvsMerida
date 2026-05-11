package es.nullpointers.eventvsmerida.exception;

/**
 * DTO de respuesta utilizado para devolver mensajes de error al frontend.
 *
 * @param error mensaje descriptivo del error producido.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record ErrorResponse(String error) {}