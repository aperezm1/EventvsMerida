package es.nullpointers.eventvsmerida.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;

/**
 * DTO para la creación de un evento.
 * La imagen puede ser proporcionada como URL (foto) o como archivo (en multipart).
 *
 * @param titulo título del evento. No puede estar vacío.
 * @param descripcion descripción del evento. No puede estar vacía.
 * @param fechaInicio fecha y hora de inicio del evento. Es obligatoria.
 * @param fechaFin fecha y hora de finalización del evento. Es obligatoria.
 * @param localizacion localización textual del evento. No puede estar vacía.
 * @param latitud latitud asociada a la ubicación del evento.
 * @param longitud longitud asociada a la ubicación del evento.
 * @param foto URL de la imagen del evento, si se proporciona mediante URL.
 * @param idUsuario identificador del usuario organizador asociado al evento.
 * @param idCategoria identificador de la categoría asociada al evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record EventoCrearRequest(
        @NotBlank
        String titulo,

        @NotBlank
        String descripcion,

        @NotNull
        LocalDateTime fechaInicio,

        @NotNull
        LocalDateTime fechaFin,

        @NotBlank
        String localizacion,

        Double latitud,
        Double longitud,

        String foto,

        @NotNull
        long idUsuario,

        @NotNull
        long idCategoria
) {}