package es.nullpointers.eventvsmerida.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.sql.Timestamp;

/**
 * DTO para la creación o actualización de un evento.
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
        Timestamp fecha,

        @NotBlank
        String localizacion,

        @NotBlank
        String foto,

        @NotNull
        long idUsuario,

        @NotNull
        long idCategoria
) {}