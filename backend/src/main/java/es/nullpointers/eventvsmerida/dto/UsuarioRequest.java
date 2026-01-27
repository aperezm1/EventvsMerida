package es.nullpointers.eventvsmerida.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class UsuarioRequest {
    @NotBlank
    private String nombre;

    @NotBlank
    private String apellidos;

    @NotNull
    private LocalDate fechaNacimiento;

    @NotBlank
    @Email
    private String email;

    @NotBlank
    private String telefono;

    @NotBlank
    @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$", message = "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número")
    private String password;

    @NotNull
    private Long idRol;
}