package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.dto.EventoResponse;
import es.nullpointers.eventvsmerida.entity.Evento;
import es.nullpointers.eventvsmerida.repository.EventoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

@Slf4j
@RequiredArgsConstructor
@Service
public class EventoService {
    private final EventoRepository repository;

    public List<EventoResponse> obtenerEventos() {
        List<Evento> eventos = repository.findAll();
        if (eventos.isEmpty()) {
            // Devuelve lista vacía en vez de lanzar excepción
            return Collections.emptyList();
        }

        List<EventoResponse> resultado = new ArrayList<>(eventos.size());
        for (Evento e : eventos) {
            EventoResponse r = new EventoResponse();
            r.setId(e.getId());
            r.setEvento(e.getEvento());
            r.setDescripcion(e.getDescripcion());
            r.setFechaHora(e.getFechaHora());
            r.setLocalizacion(e.getLocalizacion());
            r.setFoto(e.getFoto());
            // Solo IDs para evitar problemas de lazy en la serialización
            r.setUsuarioId(e.getIdUsuario() != null ? e.getIdUsuario().getId() : null);
            r.setCategoriaId(e.getIdCategoria() != null ? e.getIdCategoria().getId() : null);

            resultado.add(r);
        }
        return resultado;
    }

    public Optional<EventoResponse> obtenerEventoPorId(Long id) {
        //return obtenerEventoPorIdOExcepcion(id, "Error en EventoService.obtenerEventoPorId: No se encontró el evento con la id " + id);
        Optional<Evento> evento = repository.findById(id);

        EventoResponse r = new EventoResponse();
        r.setId(evento.get().getId());
        r.setEvento(evento.get().getEvento());
        r.setDescripcion(evento.get().getDescripcion());
        r.setFechaHora(evento.get().getFechaHora());
        r.setLocalizacion(evento.get().getLocalizacion());
        r.setFoto(evento.get().getFoto());
        // Solo IDs para evitar problemas de lazy en la serialización
        r.setUsuarioId(evento.get().getIdUsuario() != null ? evento.get().getIdUsuario().getId() : null);
        r.setCategoriaId(evento.get().getIdCategoria() != null ? evento.get().getIdCategoria().getId() : null);

        return Optional.of(r);
    }

    public Evento crearEvento(Evento evento) {
        return repository.save(evento);
    }

    public void eliminarEventoPorId(Long id) {
        if (!repository.existsById(id)) {
            throw new NoSuchElementException("Error en EventoService.eliminarEvento: No se encontró el evento con id " + id);
        }

        repository.deleteById(id);
    }
}