package es.nullpointers.eventvsmerida.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import es.nullpointers.eventvsmerida.validation.EdadValida;
import jakarta.validation.constraints.*;
import java.time.LocalDate;

/**
 * DTO para la creación de un nuevo usuario.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record UsuarioCrearRequest(
        @NotBlank
        String nombre,

        @NotBlank
        String apellidos,

        @NotNull
        @EdadValida
        @PastOrPresent(message = "La fecha de nacimiento no puede ser futura")
        @JsonFormat(pattern = "dd/MM/yyyy")
        LocalDate fechaNacimiento,

        @NotBlank
        @Email
        String email,

        @NotBlank
        @Pattern(
                regexp = "^[679]\\d{8}$",
                message = "El teléfono debe tener 9 dígitos y empezar por 6, 7 o 9"
        )
        String telefono,

        @NotBlank
        @Pattern(
                regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$",
                message = "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número"
        )
        String password,

        @NotNull
        Long idRol
) {}