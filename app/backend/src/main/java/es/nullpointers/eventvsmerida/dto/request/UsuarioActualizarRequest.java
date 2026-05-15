package es.nullpointers.eventvsmerida.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import es.nullpointers.eventvsmerida.validation.EdadValida;
import jakarta.validation.constraints.*;
import java.time.LocalDate;

/**
 * DTO para la actualización de un usuario.
 *
 * @param nombre          nuevo nombre del usuario.
 * @param apellidos       nuevos apellidos del usuario.
 * @param fechaNacimiento nueva fecha de nacimiento del usuario. No puede ser
 *                        futura
 *                        y debe cumplir la validación de edad establecida.
 * @param email           nuevo correo electrónico del usuario. Debe tener un
 *                        formato válido.
 * @param telefono        nuevo número de teléfono del usuario. Debe tener 9
 *                        dígitos
 *                        y empezar por 6, 7 o 9.
 * @param password        nueva contraseña del usuario. Debe tener al menos 8
 *                        caracteres,
 *                        una mayúscula, una minúscula y un número.
 * @param idRol           identificador del nuevo rol asignado al usuario.
 * @param fotoPath        ruta o path de la foto de perfil del usuario.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record UsuarioActualizarRequest(
        String nombre,
        String apellidos,
        @EdadValida @PastOrPresent(message = "La fecha de nacimiento no puede ser futura") @JsonFormat(pattern = "dd/MM/yyyy") LocalDate fechaNacimiento,
        @Email(message = "El correo no tiene un formato válido") String email,
        @Pattern(regexp = "^[679]\\d{8}$", message = "El teléfono debe tener 9 dígitos y empezar por 6, 7 o 9") String telefono,
        @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$", message = "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número") String password,
        Long idRol,
        String fotoPath
) {}