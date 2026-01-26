package es.nullpointers.eventvsmerida.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RolRequest {
    @NotBlank
    private String nombre;
}