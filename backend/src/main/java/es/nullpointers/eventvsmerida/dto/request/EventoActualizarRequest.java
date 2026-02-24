package es.nullpointers.eventvsmerida.dto.request;

import java.time.Instant;

/**
 * DTO para la actualización de un evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record EventoActualizarRequest(
        String titulo,
        String descripcion,
        Instant fechaHora,
        String localizacion,
        String foto,
        Long idUsuario,
        Long idCategoria
) {}