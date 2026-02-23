package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.dto.request.EventoRequest;
import es.nullpointers.eventvsmerida.dto.response.EventoResponse;
import es.nullpointers.eventvsmerida.dto.request.EventoUpdateRequest;
import es.nullpointers.eventvsmerida.entity.Evento;
import es.nullpointers.eventvsmerida.repository.EventoRepository;
import es.nullpointers.eventvsmerida.supabase.SupabaseStorage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jspecify.annotations.NonNull;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * Servicio para gestionar la lógica de negocio relacionada con la
 * entidad Evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RequiredArgsConstructor
@Service
public class EventoService {
    private final EventoRepository repository;
    private final UsuarioService usuarioService;
    private final CategoriaService categoriaService;
    private final SupabaseStorage storageUploader;

    /**
     * Método para obtener un listado con todos los eventos.
     * @return Listado de eventos.
     */
    public List<EventoResponse> obtenerEventos() {
        List<Evento> eventos = repository.findAll();
        if (eventos.isEmpty()) {
            // Devuelve lista vacía en vez de lanzar excepción
            return Collections.emptyList();
        }

        List<EventoResponse> resultado = new ArrayList<>(eventos.size());
        for (Evento evento : eventos) {
            EventoResponse eventoResponse = getEventoResponse(evento);

            resultado.add(eventoResponse);
        }
        return resultado;
    }

    /**
     * Método para obtener un evento en función de su ID.
     * @param id ID del evento.
     * @return Evento cuya ID coincide.
     */
    public EventoResponse obtenerEventoPorId(Long id) {
        Evento evento = repository.findById(id).orElseThrow(() -> new NoSuchElementException("Error en UsuarioService.obtenerUsuarioPorId: No se encontró el usuario con id" + id));

        EventoResponse eventoResponse = getEventoResponse(evento);

        return eventoResponse;
    }

    /**
     * Métooo para crear un evento.
     * @param eventoRequest DTO con los campos que se envían en la petición para crear un evento.
     * @return Devuelve el código de estado sobre la creación.
     */
    public Evento crearEvento(EventoRequest eventoRequest) {
        Evento evento = new Evento();
        evento.setTitulo(eventoRequest.getTitulo());
        evento.setDescripcion(eventoRequest.getDescripcion());
        evento.setFechaHora(eventoRequest.getFecha().toInstant());
        evento.setLocalizacion(eventoRequest.getLocalizacion());
        evento.setFoto(storageUploader.subirImagen(eventoRequest.getFoto()));
        evento.setIdUsuario(usuarioService.obtenerUsuarioPorId(eventoRequest.getIdUsuario()));
        evento.setIdCategoria(categoriaService.obtenerCategoriaPorId(eventoRequest.getIdCategoria()));

        if (repository.existsByTituloAndFechaHora(evento.getTitulo(), evento.getFechaHora())) {
            throw new DataIntegrityViolationException("Ya existe un evento con el título y fecha indicados");
        }
        return repository.save(evento);
    }

    /**
     * Método que actualiza un evento en función.
     * @param eventoUpdateRequest DTO con los campos que se pueden modificar en la petición.
     * @return Devuelve el código de estado sobre la modificación.
     */
    public Evento actualizarEvento(EventoUpdateRequest eventoUpdateRequest, Long id) {
        Evento evento = obtenerEventoSinDto(id);
        if (eventoUpdateRequest.getTitulo() != null) {
            evento.setTitulo(eventoUpdateRequest.getTitulo());
        }
        if (eventoUpdateRequest.getDescripcion() != null) {
            evento.setDescripcion(eventoUpdateRequest.getDescripcion());
        }
        if (eventoUpdateRequest.getFechaHora() != null) {
            evento.setFechaHora(eventoUpdateRequest.getFechaHora());
        }
        if (eventoUpdateRequest.getLocalizacion() != null) {
            evento.setLocalizacion(eventoUpdateRequest.getLocalizacion());
        }
        if (eventoUpdateRequest.getFoto() != null) {
            evento.setFoto(eventoUpdateRequest.getFoto());
        }
        if (eventoUpdateRequest.getUsuarioId() != null) {
            evento.setIdUsuario(usuarioService.obtenerUsuarioPorId(eventoUpdateRequest.getUsuarioId()));
        }
        if (eventoUpdateRequest.getCategoriaId() != null) {
            evento.setIdCategoria(categoriaService.obtenerCategoriaPorId(eventoUpdateRequest.getCategoriaId()));
        }

        return repository.save(evento);
    }

    /**
     * Método que elimina un evento en función de un ID dado.
     * @param id ID del evento que se desea eliminar.
     */
    public void eliminarEventoPorId(Long id) {
        if (!repository.existsById(id)) {
            throw new NoSuchElementException("Error en EventoService.eliminarEvento: No se encontró el evento con id " + id);
        }

        repository.deleteById(id);
    }

    /**
     * Método privado de la clase que recibe un evento y lo convierte al DTO EventoResponse.
     * @param evento Evento recibido por parámetro.
     * @return Devuelve un DTO de EventoResponse.
     */
    private static @NonNull EventoResponse getEventoResponse(Evento evento) {
        EventoResponse eventoResponse = new EventoResponse();
        eventoResponse.setId(evento.getId());
        eventoResponse.setTitulo(evento.getTitulo());
        eventoResponse.setDescripcion(evento.getDescripcion());
        eventoResponse.setFechaHora(evento.getFechaHora());
        eventoResponse.setLocalizacion(evento.getLocalizacion());
        eventoResponse.setFoto(evento.getFoto());
        // Solo IDs para evitar problemas de lazy en la serialización
        eventoResponse.setUsuarioId(evento.getIdUsuario() != null ? evento.getIdUsuario().getId() : null);
        eventoResponse.setCategoriaId(evento.getIdCategoria() != null ? evento.getIdCategoria().getId() : null);
        return eventoResponse;
    }

    /**
     * Método privado que se encarga de devolver un Evento con un ID pasado.
     * @param id ID del evento.
     * @return Devuelve el evento buscado si existe, si no lanza una excepción .
     */
    private Evento obtenerEventoSinDto(Long id) {
        return repository.findById(id).orElseThrow(() -> new NoSuchElementException("Error en EventooService.obtenerUsuarioPorId: No se encontró el evento con id" + id));
    }
}