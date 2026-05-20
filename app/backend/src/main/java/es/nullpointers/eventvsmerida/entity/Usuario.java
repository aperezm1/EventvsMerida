package es.nullpointers.eventvsmerida.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalDate;

/**
 * Entidad que representa a un usuario de la aplicación.
 *
 * <p>
 * Contiene los datos personales, credenciales de acceso, foto de perfil
 * y rol asociado al usuario.
 * </p>
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
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
    @Column(name = "nombre", nullable = false, length = 50)
    private String nombre;

    @NotNull
    @Column(name = "apellidos", nullable = false, length = 150)
    private String apellidos;

    @NotNull
    @Column(name = "fecha_nacimiento", nullable = false)
    private LocalDate fechaNacimiento;

    @NotNull
    @Column(name = "email", nullable = false, length = 255)
    private String email;

    @NotNull
    @Column(name = "telefono", nullable = false, length = 9)
    private String telefono;

    @NotNull
    @Size(min = 8, max = 128)
    @Column(name = "password", nullable = false, length = 128)
    private String password;

    @Column(name = "foto_path", length = 100)
    private String fotoPath;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.SET_DEFAULT)
    @JoinColumn(name = "id_rol", nullable = false)
    private Rol rol;
}