package es.nullpointers.eventvsmerida.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

/**
 * DTO para la creación o actualización de un rol.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Getter
@Setter
public class RolRequest {
    @NotBlank
    private String nombre;
}