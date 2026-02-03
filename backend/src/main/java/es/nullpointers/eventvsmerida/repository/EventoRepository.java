package es.nullpointers.eventvsmerida.repository;

import es.nullpointers.eventvsmerida.entity.Evento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;

/**
 * Repositorio que establece la comunicacion con la base de datos
 * para la entidad Evento.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Repository
public interface EventoRepository extends JpaRepository<Evento, Long> {
    boolean existsByTituloAndFechaHora(String titulo, Instant fechaHora);
}