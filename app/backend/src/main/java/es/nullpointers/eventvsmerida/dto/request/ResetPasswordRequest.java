package es.nullpointers.eventvsmerida.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * DTO para el reseteo de la contraseña.
 *
 * @param token token de recuperación de contraseña. Es obligatorio.
 * @param nuevaPassword nueva contraseña a establecer. Es obligatoria y debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record ResetPasswordRequest(
        @NotBlank(message = "El token es obligatorio")
        String token,

        @NotBlank(message = "La contraseña es obligatoria")
        @Pattern(
                regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$",
                message = "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número"
        )
        String nuevaPassword
) {
}