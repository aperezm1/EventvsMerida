package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.entity.Categoria;
import es.nullpointers.eventvsmerida.repository.CategoriaRepository;
import jakarta.persistence.NoResultException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.NoSuchElementException;

/**
 * Servicio para gestionar la logica de negocio relacionada con la
 * entidad Categoria.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RequiredArgsConstructor
@Service
public class CategoriaService {
    private final CategoriaRepository categoriaRepository;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Metodo para obtener todas las categorias.
     *
     * @return Lista de categorias.
     */
    public List<Categoria> obtenerCategorias() {
        List<Categoria> categorias = categoriaRepository.findAll();

        if(categorias.isEmpty()) {
            throw new NoResultException("Error en CategoriaService.obtenerCategorias: No se encontraron categorias en la base de datos");
        }

        return categorias;
    }

    /**
     * Metodo para obtener una categoria por su ID.
     *
     * @param id ID de la categoria a obtener.
     * @return Categoria encontrada.
     */
    public Categoria obtenerCategoriaPorId(Long id) {
        return obtenerCategoriaPorIdOExcepcion(id, "Error en CategoriaService.obtenerCategoriaPorId: No se encontró la categoria con id " + id);
    }

    /**
     * Metodo para crear una nueva categoria.
     *
     * @param categoriaNueva Datos de la categoria a crear.
     * @return Categoria creada.
     */
    public Categoria crearCategoria(Categoria categoriaNueva) {
        return categoriaRepository.save(categoriaNueva);
    }

    /**
     * Metodo para eliminar una categoria por su ID.
     *
     * @param id ID de la categoria a eliminar.
     */
    public void eliminarCategoria(Long id) {
        if (!categoriaRepository.existsById(id)) {
            throw new NoSuchElementException("Error en RolService.eliminarRol: No se encontró el rol con id " + id);
        }
        categoriaRepository.deleteById(id);
    }

    /**
     * Metodo para actualizar una categoria por su ID.
     *
     * @param id ID de la categoria a actualizar.
     * @param categoriaActualizar Datos de la categoria a actualizar.
     * @return Categoria actualizada.
     */
    public Categoria actualizarCategoria(Long id, Categoria categoriaActualizar) {
        Categoria categoriaExistente = obtenerCategoriaPorIdOExcepcion(id, "Error en CategoriaService.actualizarCategoria: No se encontró la categoria con id: " + id);
        categoriaExistente.setNombre(categoriaActualizar.getNombre());
        return categoriaRepository.save(categoriaExistente);
    }

    // ================
    // Metodos Privados
    // ================

    /**
     * Metodo privado para obtener una categoria por su ID o lanzar una excepcion si no se encuentra.
     *
     * @param id ID de la categoria a obtener.
     * @param mensajeError Mensaje de error para la excepcion.
     * @return Categoria encontrada.
     */
    private Categoria obtenerCategoriaPorIdOExcepcion(Long id, String mensajeError) {
        return categoriaRepository.findById(id).orElseThrow(() -> new NoSuchElementException(mensajeError));
    }
}