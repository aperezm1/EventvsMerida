package es.nullpointers.eventvsmerida.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entidad que representa un refresh token para extender sesiones en
 * dispositivos móviles.
 * 
 * <p>
 * Esta entidad se utiliza para almacenar los refresh tokens generados cuando un
 * usuario inicia sesión en un dispositivo móvil.
 * Cada token tiene una fecha de expiración y un estado que indica si ha sido
 * revocado o no.
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
@Table(name = "refresh_tokens")
public class RefreshToken {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(unique = true, nullable = false, length = 255)
    private String token;

    @Column(nullable = false)
    private LocalDateTime expiracion;

    @Column(nullable = false)
    private Boolean revocado = false;

    @ManyToOne
    @JoinColumn(name = "id_usuario")
    private Usuario usuario;
}