package es.nullpointers.eventvsmerida.dto.response;

import java.time.LocalDate;

/**
 * DTO para devolver los datos de un usuario.
 *
 * @param id identificador único del usuario.
 * @param nombre nombre del usuario.
 * @param apellidos apellidos del usuario.
 * @param fechaNacimiento fecha de nacimiento del usuario.
 * @param email correo electrónico del usuario.
 * @param telefono número de teléfono del usuario.
 * @param rol nombre del rol asignado al usuario.
 * @param fotoUrl URL de la foto de perfil del usuario, si tiene una asociada.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record UsuarioResponse (
        Long id,
        String nombre,
        String apellidos,
        LocalDate fechaNacimiento,
        String email,
        String telefono,
        String rol,
        String fotoUrl
){}