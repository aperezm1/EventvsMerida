package es.nullpointers.eventvsmerida.repository;

import es.nullpointers.eventvsmerida.entity.RefreshToken;
import es.nullpointers.eventvsmerida.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

/**
 * Repositorio que establece la comunicacion con la base de datos
 * para la entidad RefreshToken.
 * 
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {
    RefreshToken findByToken(String token);

    List<RefreshToken> findAllByUsuarioAndRevocadoFalse(Usuario usuario);
}