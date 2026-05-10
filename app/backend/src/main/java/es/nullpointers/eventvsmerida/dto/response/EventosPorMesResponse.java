package es.nullpointers.eventvsmerida.dto.response;

/**
 *  DTO de respuesta que representa la cantidad de eventos agrupados por mes.
 *
 * @param numMes número del mes del año. Enero corresponde al 1 y diciembre al 12.
 * @param cantidadEventos cantidad total de eventos que comienzan en ese mes.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record EventosPorMesResponse(
        int numMes,
        Long cantidadEventos
) {}
