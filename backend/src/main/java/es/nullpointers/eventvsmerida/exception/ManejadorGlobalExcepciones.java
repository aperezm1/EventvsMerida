package es.nullpointers.eventvsmerida.exception;

import com.fasterxml.jackson.databind.exc.InvalidFormatException;
import jakarta.persistence.NoResultException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.NoSuchElementException;

/**
 * Manejador global de excepciones para la aplicación.
 * Captura excepciones específicas y generales, registrando los errores
 * y devolviendo respuestas HTTP adecuadas.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@ControllerAdvice
public class ManejadorGlobalExcepciones {
    private static final Map<String, String> PATRONES_ERROR_INTEGRIDAD;

    static {
        PATRONES_ERROR_INTEGRIDAD = new LinkedHashMap<>();
        PATRONES_ERROR_INTEGRIDAD.put("Rol_nombre_key", "Error en RolService.crearRol: Nombre duplicado introducido");
        PATRONES_ERROR_INTEGRIDAD.put("Usuario_email_key", "Error en UsuarioService: Email duplicado introducido");
        PATRONES_ERROR_INTEGRIDAD.put("Usuario_telefono_key", "Error en UsuarioService: Teléfono duplicado introducido");
    }

    /**
     * Maneja la excepción NoResultException.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 204 No Content.
     */
    @ExceptionHandler(NoResultException.class)
    public ResponseEntity<Void> manejadorNoResultException(NoResultException e) {
        log.error(e.getMessage());
        return ResponseEntity.noContent().build();
    }

    /**
     * Maneja la excepción NoSuchElementException.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 404 Not Found.
     */
    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<Void> manejadorNoSuchElementException(NoSuchElementException e) {
        log.error(e.getMessage());
        return ResponseEntity.notFound().build();
    }

    /**
     * Maneja la excepción MethodArgumentNotValidException.
     * Se lanza cuando la validación de los argumentos de un método falla,
     * normalmente por anotaciones de validación en los DTOs (por ejemplo, @NotNull, @Email).
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Void> manejadorMethodArgumentNotValidException(MethodArgumentNotValidException e) {
        String mensaje = e.getMessage();

        if (mensaje.contains("crearRol")) {
            log.error("Error en RolService.crearRol: [nombre: no debe estar vacío ni nulo] ");
        } else if (mensaje.contains("crearUsuario")) {
            StringBuilder errores = new StringBuilder();

            for (FieldError error : e.getBindingResult().getFieldErrors()) {
                errores.append("[").append(error.getField()).append(": ").append(error.getDefaultMessage()).append("] ");
            }

            log.error("Error en UsuarioService.crearUsuario: " + errores.toString().trim());
        } else if (mensaje.contains("actualizarUsuario")) {
            StringBuilder errores = new StringBuilder();

            for (FieldError error : e.getBindingResult().getFieldErrors()) {
                errores.append("[").append(error.getField()).append(": ").append(error.getDefaultMessage()).append("] ");
            }

            log.error("Error en UsuarioService.actualizarUsuario: " + errores.toString().trim());
        } else {
            log.error(mensaje);
        }

        return ResponseEntity.badRequest().build();
    }

    /**
     * Maneja la excepción DataIntegrityViolationException.
     * Se controla cuando se intenta crear un objeto de una tabla con algun
     * dato que viola restricciones de integridad.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Void> manejadorDataIntegrityViolationException(DataIntegrityViolationException e) {
        boolean encontrado = false;

        for (Map.Entry<String, String> entry : PATRONES_ERROR_INTEGRIDAD.entrySet()) {
            if (e.getMessage().contains(entry.getKey())) {
                log.error(entry.getValue());
                encontrado = true;
                break;
            }
        }

        if (!encontrado) {
            log.error(e.getMessage());
        }

        return ResponseEntity.badRequest().build();
    }

    /**
     * Maneja la excepción HttpMessageNotReadableException.
     * Se lanza cuando el cuerpo de la petición no puede deserializarse correctamente,
     * normalmente por errores de formato en los datos recibidos (por ejemplo, fechas mal formateadas).
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Void> manejadorHttpMessageNotReadableException(HttpMessageNotReadableException e) {
        Throwable causa = e.getMostSpecificCause();
        String metodo = e.getStackTrace().length > 0 ? e.getStackTrace()[0].getMethodName() : "desconocido";

        if (causa instanceof InvalidFormatException ife && !ife.getPath().isEmpty()) {
            String campo = ife.getPath().get(0).getFieldName();
            String tipo = ife.getTargetType().getSimpleName();
            log.error("Excepción en método '{}': Error de formato en el campo '{}', tipo esperado '{}'. Detalle: {}", metodo, campo, tipo, causa.getMessage());
        } else {
            log.error("Excepción en método '{}': Error de formato en los datos recibidos. Detalle: {}", metodo, causa.getMessage());
        }
        return ResponseEntity.badRequest().build();
    }

    /**
     * Maneja cualquier otra excepción no específica.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 500 Internal Server Error.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Void> manejadoreGeneralException(Exception e) {
        log.error(e.getMessage());
        return ResponseEntity.internalServerError().build();
    }
}