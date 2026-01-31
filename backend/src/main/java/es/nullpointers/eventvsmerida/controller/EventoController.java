package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.EventoRequest;
import es.nullpointers.eventvsmerida.dto.EventoResponse;
import es.nullpointers.eventvsmerida.dto.UsuarioRequest;
import es.nullpointers.eventvsmerida.entity.Categoria;
import es.nullpointers.eventvsmerida.entity.Evento;
import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.service.EventoService;
import es.nullpointers.eventvsmerida.service.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/eventos")
public class EventoController {
    private final EventoService eventoService;
    private final UsuarioService usuarioService;

    @GetMapping("/all")
    public ResponseEntity<List<EventoResponse>> obtenerEventos() {
        List<EventoResponse> eventos = eventoService.obtenerEventos();
        return ResponseEntity.ok(eventos);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Optional> obtenerEventoPorId(@PathVariable Long id) {
        Optional<EventoResponse> evento = eventoService.obtenerEventoPorId(id);
        return ResponseEntity.ok(evento);
    }

    @PostMapping("/add")
    public ResponseEntity<Evento> crearEvento(@Valid @RequestBody EventoRequest eventoRequest) {
        Evento evento = new Evento();
        evento.setEvento(eventoRequest.getEvento());
        evento.setDescripcion(eventoRequest.getDescripcion());
        evento.setFechaHora(eventoRequest.getFecha().toInstant());
        evento.setLocalizacion(eventoRequest.getLocalizacion());
        evento.setFoto(eventoRequest.getFoto());
        evento.setIdUsuario(usuarioService.obtenerUsuarioPorId(eventoRequest.getIdUsuario()));
        Categoria categoria = new Categoria();
        categoria.setId(1L);
        evento.setIdCategoria(categoria);

        eventoService.crearEvento(evento);
        return ResponseEntity.status(HttpStatus.CREATED).body(evento);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> eliminarEvento(@PathVariable Long id) {
        eventoService.eliminarEventoPorId(id);
        return ResponseEntity.noContent().build();
    }
}
