package es.nullpointers.eventvsmerida.dto;

import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;


@Getter
@Setter
@JsonPropertyOrder({
        "id",
        "evento",
        "descripcion",
        "fechaHora",
        "localizacion",
        "foto",
        "usuarioId",
        "categoriaId"
})
public class EventoResponse {
    private Long id;
    private String evento;
    private String descripcion;
    private Instant fechaHora;
    private String localizacion;
    private String foto;
    private Long usuarioId;
    private Long categoriaId;
}