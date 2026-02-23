package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.request.EventoRequest;
import es.nullpointers.eventvsmerida.dto.response.EventoResponse;
import es.nullpointers.eventvsmerida.dto.request.EventoUpdateRequest;
import es.nullpointers.eventvsmerida.entity.Evento;
import es.nullpointers.eventvsmerida.service.EventoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST que recibe las peticiones HTTP relacionadas con la
 * entidad Evento y las delega al servicio correspondiente.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/eventos")
public class EventoController {
    private final EventoService eventoService;

    /**
     * Método GET que llama a EventoService para obtener todos los eventos.
     * @return Listado de eventos.
     */
    @GetMapping("/all")
    public ResponseEntity<List<EventoResponse>> obtenerEventos() {
        List<EventoResponse> eventos = eventoService.obtenerEventos();
        return ResponseEntity.ok(eventos);
    }

    /**
     * Método GET que llama a EventoService para obtener un evento por su ID.
     * @param id ID del evento.
     * @return Evento cuya ID coincida.
     */
    @GetMapping("/{id}")
    public ResponseEntity<EventoResponse> obtenerEventoPorId(@PathVariable Long id) {
        EventoResponse eventoResponse = eventoService.obtenerEventoPorId(id);
        return ResponseEntity.ok(eventoResponse);
    }

    /**
     * Método POST que llama a EventoService para crear un evento.
     * @param eventoRequest DTO con los campos de la petición.
     * @return Devuelve el código de estado de la petición.
     */
    @PostMapping("/add")
    public ResponseEntity<Evento> crearEvento(@Valid @RequestBody EventoRequest eventoRequest) {
        Evento evento = eventoService.crearEvento(eventoRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(evento);
    }

    /**
     * Método PATCH que llama a EventoService para actulizar un evento pasado por ID.
     * @param eventoUpdateRequest DTO con los campos de la petición.
     * @param id ID del evento.
     * @return Devuelve el código de estado de la petición.
     */
    @PatchMapping("update/{id}")
    public ResponseEntity<Evento> actualizarEvento (@Valid @RequestBody EventoUpdateRequest eventoUpdateRequest, @PathVariable Long id) {
        Evento evento = eventoService.actualizarEvento(eventoUpdateRequest, id);
        return ResponseEntity.ok(evento);
    }

    /**
     * Método DELETE que llama a EventoService para eliminar un evento pasado por ID.
     * @param id ID del evento.
     * @return Devuelve el código de estado de la petición.
     */
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> eliminarEvento(@PathVariable Long id) {
        eventoService.eliminarEventoPorId(id);
        return ResponseEntity.noContent().build();
    }
}
