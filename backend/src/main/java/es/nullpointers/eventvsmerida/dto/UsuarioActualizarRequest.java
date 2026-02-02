package es.nullpointers.eventvsmerida.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.Email;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import jakarta.validation.constraints.Pattern;

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

    @JsonFormat(pattern = "dd/MM/yyyy")
    private LocalDate fechaNacimiento;

    @Email(message = "El email debe tener un formato válido")
    @Pattern(regexp = "^$|.+", message = "El email puede estar vacío o tener un formato válido")
    private String email;

    @Pattern(regexp = "^$|^[679]\\d{8}$", message = "El teléfono debe estar vacío o tener 9 dígitos y empezar por 6, 7 o 9")
    private String telefono;

    @Pattern(regexp = "^$|^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$", message = "La contraseña debe estar vacía o tener al menos 8 caracteres, una mayúscula, una minúscula y un número")
    private String password;

    private Long idRol;
}