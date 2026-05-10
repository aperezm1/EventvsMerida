package es.nullpointers.eventvsmerida.dto.request;

import java.time.LocalDateTime;

/**
 * DTO para la actualización de un evento.
 *
 * @param titulo nuevo título del evento.
 * @param descripcion nueva descripción del evento.
 * @param fechaInicio nueva fecha y hora de inicio del evento.
 * @param fechaFin nueva fecha y hora de finalización del evento.
 * @param localizacion nueva localización textual del evento.
 * @param latitud nueva latitud asociada a la ubicación del evento.
 * @param longitud nueva longitud asociada a la ubicación del evento.
 * @param foto nueva URL de la imagen del evento, si se actualiza mediante URL.
 * @param idUsuario identificador del usuario organizador asociado al evento.
 * @param idCategoria identificador de la categoría asociada al evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record EventoActualizarRequest(
        String titulo,
        String descripcion,
        LocalDateTime fechaInicio,
        LocalDateTime fechaFin,
        String localizacion,
        Double latitud,
        Double longitud,
        String foto,
        Long idUsuario,
        Long idCategoria
) {}