package es.nullpointers.eventvsmerida.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import es.nullpointers.eventvsmerida.validation.EdadValida;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;

/**
 * DTO para la actualización de un usuario.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Getter
@Setter
public class UsuarioActualizarRequest implements UsuarioBaseRequest {
    private String nombre;

    private String apellidos;

    @EdadValida
    @PastOrPresent(message = "La fecha de nacimiento no puede ser futura")
    @JsonFormat(pattern = "dd/MM/yyyy")
    private LocalDate fechaNacimiento;

    @Email
    private String email;

    @Pattern(regexp = "^[679]\\d{8}$", message = "El teléfono debe tener 9 dígitos y empezar por 6, 7 o 9")
    private String telefono;

    @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$", message = "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número")
    private String password;

    private Long idRol;
}