package es.nullpointers.eventvsmerida.dto.request;

import jakarta.validation.constraints.NotBlank;

/**
 * DTO para la solicitud de renovación de token.
 * 
 * @param refreshToken token de renovación que se utilizará para obtener un nuevo token de acceso.
 * 
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record RefreshTokenRequest(
        @NotBlank String refreshToken
) {}