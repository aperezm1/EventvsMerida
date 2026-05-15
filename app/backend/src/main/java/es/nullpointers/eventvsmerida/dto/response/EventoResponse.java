package es.nullpointers.eventvsmerida.dto.response;

import java.time.LocalDateTime;

/**
 * DTO para devolver los datos de un evento.
 *
 * @param id              identificador único del evento.
 * @param titulo          título del evento.
 * @param descripcion     descripción del evento.
 * @param fechaInicio     fecha y hora de inicio del evento.
 * @param fechaFin        fecha y hora de finalización del evento.
 * @param localizacion    localización textual del evento.
 * @param latitud         latitud asociada a la ubicación del evento.
 * @param longitud        longitud asociada a la ubicación del evento.
 * @param foto            URL de la imagen del evento.
 * @param emailUsuario    correo electrónico del usuario asociado al evento.
 * @param nombreCategoria nombre de la categoría asociada al evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record EventoResponse(
        Long id,
        String titulo,
        String descripcion,
        LocalDateTime fechaInicio,
        LocalDateTime fechaFin,
        String localizacion,
        Double latitud,
        Double longitud,
        String foto,
        String emailUsuario,
        String nombreCategoria
) {}