package es.nullpointers.eventvsmerida.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entidad que representa un token de restablecimiento de contraseña.
 * 
 * <p>
 * Esta entidad se utiliza para almacenar los tokens generados cuando un usuario
 * solicita restablecer su contraseña.
 * Cada token tiene una fecha de expiración y un estado que indica si ya ha sido
 * utilizado o no.
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
@Table(name = "password_reset_tokens")
public class PasswordResetToken {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(unique = true, nullable = false)
    private String token;

    @Column(nullable = false)
    private LocalDateTime expiracion;

    private Boolean usado = false;

    @ManyToOne
    @JoinColumn(name = "id_usuario")
    private Usuario usuario;
}