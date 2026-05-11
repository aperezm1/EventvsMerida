package es.nullpointers.eventvsmerida.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.validation.constraints.NotNull;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.Setter;

import java.io.Serializable;

/**
 * Clase embebida que representa la clave primaria compuesta de la relación
 * entre un usuario y un evento.
 *
 * <p>Se utiliza como identificador de la entidad {@link UsuarioEvento},
 * combinando el identificador del usuario y el identificador del evento.</p>
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Getter
@Setter
@EqualsAndHashCode
@Embeddable
public class UsuarioEventoId implements Serializable {
    private static final long serialVersionUID = -8917487241937299810L;
    @NotNull
    @Column(name = "id_usuario", nullable = false)
    private Long idUsuario;

    @NotNull
    @Column(name = "id_evento", nullable = false)
    private Long idEvento;
}