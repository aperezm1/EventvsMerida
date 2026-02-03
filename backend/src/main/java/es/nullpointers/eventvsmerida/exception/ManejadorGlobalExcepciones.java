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

    private static final Map<String, String> ERRORES = Map.of(
            "crearRol", "Error en RolService.crearRol: ",
            "actualizarRol", "Error en RolService.actualizarRol: ",
            "crearUsuario", "Error en UsuarioService.crearUsuario: ",
            "actualizarUsuario", "Error en UsuarioService.actualizarUsuario: ",
            "crearCategoria", "Error en CategoriaService.crearCategoria: ",
            "actualizarCategoria", "Error en CategoriaService.actualizarCategoria: ",
            "Rol_nombre_key", "Nombre duplicado introducido",
            "Usuario_email_key", "Email duplicado introducido",
            "Usuario_telefono_key", "Teléfono duplicado introducido",
            "Categoria_nombre_key", "Nombre duplicado introducido"
    );

    // ========================
    // Métodos ExceptionHandler
    // ========================

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
     * normalmente por anotaciones de validación en los DTOs (por ejemplo @NotNull, @Email, @Pattern).
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Void> manejadorMethodArgumentNotValidException(MethodArgumentNotValidException e) {
        String mensaje = e.getMessage();
        String errores = construirErroresValidacion(e);
        log.error(obtenerMensajePersonalizado(mensaje, errores));
        return ResponseEntity.badRequest().build();
    }

    /**
     * Maneja la excepción DataIntegrityViolationException.
     * Se controla cuando se intenta crear un objeto de una tabla con algún
     * dato que viola restricciones de integridad.
     *
     * @param e La excepción capturada.
     * @return Una respuesta HTTP 400 Bad Request.
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Void> manejadorDataIntegrityViolationException(DataIntegrityViolationException e) {
        String mensaje = e.getMessage();
        String claseMetodo = obtenerClaseMetodoDesdeStackTrace(e.getStackTrace());
        String logMsg = obtenerMensajePersonalizado(mensaje, null);
        log.error("Error en {}: {}", claseMetodo, logMsg);
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
        log.error("Causa: {}, Mensaje: {}", causa.getClass().getName(), causa.getMessage());

        if (causa instanceof InvalidFormatException ife) {
            if (!ife.getPath().isEmpty()) {
                String campo = ife.getPath().getFirst().getFieldName();
                String tipo = ife.getTargetType().getSimpleName();
                log.error("Excepción en método '{}': Error de formato en el campo '{}', tipo esperado '{}'. Detalle: {}", metodo, campo, tipo, causa.getMessage());
            } else {
                log.error("Excepción en método '{}': InvalidFormatException sin path. Detalle: {}", metodo, causa.getMessage());
            }
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

    // ================
    // Métodos Privados
    // ================

    /**
     * Método auxiliar para construir un mensaje de error detallado
     * a partir de una excepción MethodArgumentNotValidException.
     *
     * @param e La excepción capturada.
     * @return Una cadena con los detalles de los errores de validación.
     */
    private String construirErroresValidacion(MethodArgumentNotValidException e) {
        StringBuilder errores = new StringBuilder();

        for (FieldError error : e.getBindingResult().getFieldErrors()) {
            errores.append("[").append(error.getField()).append(": ").append(error.getDefaultMessage()).append("] ");
        }

        return errores.toString().trim();
    }

    /**
     * Método auxiliar para obtener la clase y el método
     * desde el stack trace de una excepción.
     *
     * @param stackTrace El stack trace de la excepción.
     * @return Una cadena con el formato "Clase.Método" o "desconocido" si no se encuentra.
     */
    private String obtenerClaseMetodoDesdeStackTrace(StackTraceElement[] stackTrace) {
        for (StackTraceElement ste : stackTrace) {
            String className = ste.getClassName();

            // Filtrar solo las clases del paquete de la aplicación, excluyendo excepciones y clases internas
            if (className.startsWith("es.nullpointers.eventvsmerida") && !className.contains("exception") && !className.contains("$")) {
                return className.substring(className.lastIndexOf('.') + 1) + "." + ste.getMethodName();
            }
        }

        return "desconocido";
    }

    /**
     * Método auxiliar para obtener un mensaje personalizado
     * basado en el mensaje original y un mapa de errores conocidos.
     *
     * @param mensaje El mensaje original de la excepción.
     * @param errores Detalles adicionales de errores, si los hay.
     * @return Un mensaje personalizado si se encuentra una coincidencia, o el mensaje original.
     */
    private String obtenerMensajePersonalizado(String mensaje, String errores) {
        for (Map.Entry<String, String> entry : ERRORES.entrySet()) {
            if (mensaje.contains(entry.getKey())) {
                return entry.getValue() + (errores != null ? errores : "");
            }
        }

        return mensaje;
    }
}