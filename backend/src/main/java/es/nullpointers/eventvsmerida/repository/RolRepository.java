package es.nullpointers.eventvsmerida.repository;

import es.nullpointers.eventvsmerida.entity.Rol;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RolRepository extends JpaRepository<Rol, Long> {
}
