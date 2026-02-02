package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.entity.Categoria;
import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.repository.CategoriaRepository;
import jakarta.persistence.NoResultException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.NoSuchElementException;

@Slf4j
@RequiredArgsConstructor
@Service
public class CategoriaService {
    private final CategoriaRepository categoriaRepository;

    // ============
    // Metodos CRUD
    // ============

    public List<Categoria> obtenerCategorias() {
        List<Categoria> categorias = categoriaRepository.findAll();

        if(categorias.isEmpty()) {
            throw new NoResultException("Error en CategoriaService.obtenerCategorias: No se encontraron categorias en la base de datos");
        }
        return categorias;
    }

    public Categoria obtenerCategoriaPorId(Long id) {
        return obtenerCategoriaPorIdOExcepcion(id, "Error en CategoriaService.obtenerCategoriaPorId: No se encontró la categoria con id " + id);
    }

    public Categoria crearCategoria(Categoria categoriaNuevo) {
        return categoriaRepository.save(categoriaNuevo);
    }

    public void eliminarCategoria(Long id) {
        if (!categoriaRepository.existsById(id)) {
            throw new NoSuchElementException("Error en RolService.eliminarRol: No se encontró el rol con id " + id);
        }
        categoriaRepository.deleteById(id);
    }

    public Categoria actualizarCategoria(Long id, Categoria categoriaActualizar) {
        Categoria categoriaExistente = obtenerCategoriaPorIdOExcepcion(id, "Error en CategoriaService.actualizarCategoria: No se encontró la categoria con id: " + id);
        categoriaExistente.setNombre(categoriaActualizar.getNombre());
        return categoriaRepository.save(categoriaExistente);
    }

    // ================
    // Metodos Privados
    // ================

    private Categoria obtenerCategoriaPorIdOExcepcion(Long id, String mensajeError) {
        return categoriaRepository.findById(id).orElseThrow(() -> new NoSuchElementException(mensajeError));
    }
}
