package es.nullpointers.eventvsmerida.repository;

import es.nullpointers.eventvsmerida.entity.PasswordResetToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repositorio que establece la comunicacion con la base de datos para la
 * entidad PassResetToken.
 * 
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {
    PasswordResetToken findByToken(String token);
}