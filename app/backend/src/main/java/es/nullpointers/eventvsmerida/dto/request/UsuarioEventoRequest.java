package es.nullpointers.eventvsmerida.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;

/**
 * DTO para la creación o actualización de una relación entre un usuario y un
 * evento.
 *
 * @param emailUsuario      correo electrónico del usuario. No puede estar vacío
 *                          y debe tener un formato válido.
 * @param tituloEvento      título del evento que se quiere guardar o eliminar.
 *                          No puede estar vacío.
 * @param fechaInicioEvento fecha y hora de inicio del evento.
 * @param fechaFinEvento    fecha y hora de finalización del evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record UsuarioEventoRequest(
        @NotBlank @Email String emailUsuario,
        @NotBlank String tituloEvento,
        @NotNull LocalDateTime fechaInicioEvento,
        @NotNull LocalDateTime fechaFinEvento
) {}