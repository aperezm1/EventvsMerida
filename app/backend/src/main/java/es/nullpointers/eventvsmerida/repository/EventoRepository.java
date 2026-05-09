package es.nullpointers.eventvsmerida.repository;

import es.nullpointers.eventvsmerida.dto.response.EventosPorCategoriaResponse;
import es.nullpointers.eventvsmerida.entity.Evento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

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
    boolean existsByTituloAndFechaInicioAndFechaFin(String titulo, LocalDateTime fechaInicio, LocalDateTime fechaFin);

    Optional<Evento> findByTituloAndFechaInicioAndFechaFin(String titulo, LocalDateTime fechaInicio, LocalDateTime fechaFin);

    List<Evento> findByCategoria_IdIn(List<Long> categoriaIds);

    Page<Evento> findByFechaFinAfter(LocalDateTime fechaFin, Pageable pageable);

    @Query(value = "SELECT e.* FROM \"Evento\" e JOIN \"Categoria\" c ON e.id_categoria = c.id " +
            "WHERE unaccent(lower(e.titulo)) LIKE concat('%', unaccent(lower(:q)), '%') " +
            //"OR unaccent(lower(e.descripcion)) LIKE concat('%', unaccent(lower(:q)), '%') " +
            "OR unaccent(lower(e.localizacion)) LIKE concat('%', unaccent(lower(:q)), '%') " +
            "OR unaccent(lower(c.nombre)) LIKE concat('%', unaccent(lower(:q)), '%')", countQuery = "SELECT COUNT(*) FROM \"Evento\" e JOIN \"Categoria\" c ON e.id_categoria = c.id "
                    +
                    "WHERE unaccent(lower(e.titulo)) LIKE concat('%', unaccent(lower(:q)), '%') " +
                    //"OR unaccent(lower(e.descripcion)) LIKE concat('%', unaccent(lower(:q)), '%') " +
                    "OR unaccent(lower(e.localizacion)) LIKE concat('%', unaccent(lower(:q)), '%') " +
                    "OR unaccent(lower(c.nombre)) LIKE concat('%', unaccent(lower(:q)), '%')", nativeQuery = true)
    Page<Evento> searchByQuery(@Param("q") String q, Pageable pageable);


    @Query("""
        SELECT MONTH(e.fechaInicio), COUNT(e)
        FROM Evento e
        WHERE YEAR(e.fechaInicio) = 2026
        GROUP BY MONTH(e.fechaInicio)
        ORDER BY MONTH(e.fechaInicio)
    """)
    List<Object[]> contarEventosPorMes();


    @Query(value = """
    SELECT c.nombre AS categoria, COUNT(e.id) AS total
    FROM "Categoria" c
    LEFT JOIN "Evento" e ON e.id_categoria = c.id
    GROUP BY c.id, c.nombre
    ORDER BY COUNT(e.id) DESC
""", nativeQuery = true)
    List<EventosPorCategoriaResponse> contarEventosPorCategoria();

}
