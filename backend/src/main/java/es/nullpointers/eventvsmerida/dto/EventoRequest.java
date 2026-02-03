package es.nullpointers.eventvsmerida.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.sql.Timestamp;

@Getter
@Setter
public class EventoRequest {
    @NotBlank
    private String titulo;

    @NotBlank
    private String descripcion;

    @NotNull
    private Timestamp fecha;

    @NotBlank
    private String localizacion;

    @NotBlank
    private String foto;

    @NotNull
    private long idUsuario;

    @NotNull
    private long idCategoria;
}