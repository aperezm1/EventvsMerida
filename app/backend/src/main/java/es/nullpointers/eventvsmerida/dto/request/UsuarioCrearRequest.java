package es.nullpointers.eventvsmerida.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import es.nullpointers.eventvsmerida.validation.EdadValida;
import jakarta.validation.constraints.*;
import java.time.LocalDate;

/**
 * DTO para la creación de un nuevo usuario.
 *
 * @param nombre nombre del usuario. Es obligatorio.
 * @param apellidos apellidos del usuario. Son obligatorios.
 * @param fechaNacimiento fecha de nacimiento del usuario. Es obligatoria,
 *                        no puede ser futura y debe cumplir la validación de edad establecida.
 * @param email correo electrónico del usuario. Es obligatorio y debe tener un formato válido.
 * @param telefono número de teléfono del usuario. Es obligatorio, debe tener 9 dígitos
 *                 y empezar por 6, 7 o 9.
 * @param password contraseña del usuario. Es obligatoria y debe tener al menos 8 caracteres,
 *                 una mayúscula, una minúscula y un número.
 * @param idRol identificador del rol asignado al usuario. Es obligatorio.
 * @param fotoPath ruta o path de la foto de perfil del usuario, si se proporciona.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record UsuarioCrearRequest(
        @NotBlank(message = "El nombre es obligatorio")
        String nombre,

        @NotBlank(message = "Los apellidos son obligatorios")
        String apellidos,

        @NotNull(message = "La fecha de nacimiento es obligatoria")
        @EdadValida
        @PastOrPresent(message = "La fecha de nacimiento no puede ser futura")
        @JsonFormat(pattern = "dd/MM/yyyy")
        LocalDate fechaNacimiento,

        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no tiene un formato válido")
        String email,

        @NotBlank(message = "El teléfono es obligatorio")
        @Pattern(
                regexp = "^[679]\\d{8}$",
                message = "El teléfono debe tener 9 dígitos y empezar por 6, 7 o 9"
        )
        String telefono,

        @NotBlank(message = "La contraseña es obligatoria")
        @Pattern(
                regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$",
                message = "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número"
        )
        String password,

        @NotNull
        Long idRol,

        String fotoPath
) {}