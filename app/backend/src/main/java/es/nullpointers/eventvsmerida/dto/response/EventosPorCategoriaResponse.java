package es.nullpointers.eventvsmerida.dto.response;

public record EventosPorCategoriaResponse(
        String categoria,
        Long total
) {}
