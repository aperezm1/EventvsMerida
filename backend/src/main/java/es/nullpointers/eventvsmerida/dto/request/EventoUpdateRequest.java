package es.nullpointers.eventvsmerida.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Getter
@Setter
public class EventoUpdateRequest {
    private String titulo;
    private String descripcion;
    private Instant fechaHora;
    private String localizacion;
    private String foto;
    private Long usuarioId;
    private Long categoriaId;
}
