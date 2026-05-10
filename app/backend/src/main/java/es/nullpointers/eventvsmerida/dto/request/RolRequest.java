package es.nullpointers.eventvsmerida.dto.request;

import jakarta.validation.constraints.NotBlank;

/**
 * DTO para la creación o actualización de un rol.
 *
 * @param nombre nombre del rol. No puede estar vacío ni contener solo espacios.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record RolRequest(
        @NotBlank
        String nombre
) {}