package es.nullpointers.eventvsmerida.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Getter
@Setter
public class EventoUpdateRequest {
    private String evento;
    private String descripcion;
    private Instant fechaHora;
    private String localizacion;
    private String foto;
    private Long usuarioId;
    private Long categoriaId;
}
