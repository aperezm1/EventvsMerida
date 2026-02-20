package es.nullpointers.eventvsmerida.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalDate;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "\"Usuario\"")
public class Usuario {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @NotNull
    @Pattern(regexp = "^[A-Za-zÀ-ÿ]+$", message = "El nombre solo puede contener letras")
    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @NotNull
    @Pattern(regexp = "^[A-Za-zÀ-ÿ]+$", message = "El apellido solo puede contener letras")
    @Column(name = "apellidos", nullable = false, length = 100)
    private String apellidos;

    @NotNull
    @Column(name = "fecha_nacimiento", nullable = false)
    private LocalDate fechaNacimiento;

    @NotNull
    @Email(message = "Correo no válido")
    @Column(name = "email", nullable = false, length = 255)
    private String email;

    @NotNull
    @Pattern(regexp = "^\\d{9}$", message = "El teléfono debe tener 9 dígitos")
    @Column(name = "telefono", nullable = false, length = 9)
    private String telefono;

    @NotNull
    @Pattern(
            regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$",
            message = "La contraseña debe tener al menos 8 caracteres, incluyendo mayúscula, minúscula, número y símbolo"
    )
    @Column(name = "password", nullable = false, length = 255)
    private String password;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.SET_DEFAULT)
    @JoinColumn(name = "id_rol", nullable = false)
    private Rol idRol;
}