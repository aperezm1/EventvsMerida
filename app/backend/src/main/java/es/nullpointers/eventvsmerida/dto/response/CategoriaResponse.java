package es.nullpointers.eventvsmerida.dto.response;

/**
 * DTO para devolver los datos de una categoría.
 *
 * @param id identificador único de la categoría.
 * @param nombre nombre de la categoría.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record CategoriaResponse(
        Long id,
        String nombre
) {}