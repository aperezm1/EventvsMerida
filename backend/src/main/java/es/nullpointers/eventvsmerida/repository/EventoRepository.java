package es.nullpointers.eventvsmerida.repository;

import es.nullpointers.eventvsmerida.entity.Evento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EventoRepository extends JpaRepository<Evento, Long> {
    
}
