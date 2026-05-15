package es.nullpointers.eventvsmerida.dto.response;

/**
 * DTO de respuesta que representa la cantidad de eventos agrupados por
 * categoría.
 *
 * @param categoria nombre de la categoría.
 * @param total     cantidad total de eventos asociados a esa categoría.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record EventosPorCategoriaResponse(
        String categoria,
        Long total
) {}