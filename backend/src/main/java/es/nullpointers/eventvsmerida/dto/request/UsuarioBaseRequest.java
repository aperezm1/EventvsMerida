package es.nullpointers.eventvsmerida.dto.request;

import java.time.LocalDate;

/**
 * Interfaz que define los métodos para obtener los datos básicos de un usuario.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public interface UsuarioBaseRequest {
    String getNombre();
    String getApellidos();
    LocalDate getFechaNacimiento();
    String getEmail();
    String getTelefono();
    String getPassword();
    Long getIdRol();
}