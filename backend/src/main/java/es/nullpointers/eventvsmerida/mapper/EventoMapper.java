package es.nullpointers.eventvsmerida.mapper;

import es.nullpointers.eventvsmerida.dto.request.EventoCrearRequest;
import es.nullpointers.eventvsmerida.dto.response.EventoResponse;
import es.nullpointers.eventvsmerida.entity.Categoria;
import es.nullpointers.eventvsmerida.entity.Evento;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.supabase.SupabaseStorage;

import java.time.Instant;

/**
 * Clase mapper que convierte entre objetos DTO y entidades
 * relacionadas con la entidad Evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public class EventoMapper {

    /**
     * Metodo que convierte un objeto EventoCrearRequest a una entidad Evento.
     *
     * @param request Objeto DTO con los datos del evento a crear.
     * @param usuario Usuario organizador del evento.
     * @param categoria Categoria del evento.
     * @param storageUploader Para subir la imagen al bucket de Supabase
     * @return Entidad Evento creada a partir del DTO y las entidades relacionadas.
     */
    public static Evento convertirAEntidad(EventoCrearRequest request, Usuario usuario, Categoria categoria, SupabaseStorage storageUploader) {
        Evento evento = new Evento();

        evento.setTitulo(request.titulo());
        evento.setDescripcion(request.descripcion());
        evento.setFechaHora(request.fecha().toInstant());
        evento.setLocalizacion(request.localizacion());
        evento.setFoto(storageUploader.subirImagen(request.foto()));
        evento.setUsuario(usuario);
        evento.setCategoria(categoria);

        return evento;
    }

    /**
     * Metodo que convierte una entidad Evento a un objeto EventoResponse.
     *
     * @param evento Entidad Evento a convertir.
     * @return Objeto DTO con los datos del evento.
     */
    public static EventoResponse convertirAResponse(Evento evento) {
        String titulo = evento.getTitulo();
        String descripcion = evento.getDescripcion();
        Instant fechaHora = evento.getFechaHora();
        String localizacion = evento.getLocalizacion();
        String urlFoto = evento.getFoto();
        String emailOrganizador = evento.getUsuario().getEmail();
        String categoria = evento.getCategoria().getNombre();

        return new EventoResponse(titulo, descripcion, fechaHora, localizacion, urlFoto, emailOrganizador, categoria);
    }
}