package es.nullpointers.eventvsmerida.exception;

import jakarta.persistence.NoResultException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.NoSuchElementException;

/**
 * Manejador global de excepciones para la aplicación.
 * Captura excepciones específicas y generales, registrando los errores
 * y devolviendo respuestas HTTP adecuadas.
 */
@Slf4j
@ControllerAdvice
public class ManejadorGlobalExcepciones {

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
     * Se controla cuando se intenta crear un objeto de una tabla con algun argumento inválido.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Void> manejadorMethodArgumentNotValidException(MethodArgumentNotValidException e) {
        if (e.getMessage().contains("crearRol")) {
            log.error("Error en RolService.crearRol: Nombre blank o nulo introducido");
        } else {
            log.error(e.getMessage());
        }

        return ResponseEntity.badRequest().build();
    }

    /**
     * Maneja la excepción DataIntegrityViolationException.
     * Se controla cuando se intenta crear un objeto de una tabla con algun dato que viola restricciones de integridad.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Void> manejadorDataIntegrityViolationException(DataIntegrityViolationException e) {
        if (e.getMessage().contains("Rol_nombre_key")) {
            log.error("Error en RolService.crearRol: Nombre duplicado introducido");
        } else {
            log.error(e.getMessage());
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