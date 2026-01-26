package es.nullpointers.eventvsmerida.exception;

import jakarta.persistence.NoResultException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.NoSuchElementException;

/**
 * Manejador global de excepciones para la aplicación.
 * Captura excepciones específicas y generales, registrando los errores y devolviendo respuestas HTTP adecuadas.
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