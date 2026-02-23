package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.request.CategoriaRequest;
import es.nullpointers.eventvsmerida.entity.Categoria;
import es.nullpointers.eventvsmerida.mapper.CategoriaMapper;
import es.nullpointers.eventvsmerida.service.CategoriaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST que recibe las peticiones HTTP relacionadas con la
 * entidad Categoria y las delega al servicio correspondiente.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/categorias")
public class CategoriaController {
    private final CategoriaService categoriaService;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Metodo GET que llama al servicio para obtener todas las categorias.
     *
     * @return ResponseEntity con la categoria creada y el estado HTTP 200 (OK).
     */
    @GetMapping("/all")
    public ResponseEntity<List<Categoria>> obtenerCategorias() {
        List<Categoria> categorias = categoriaService.obtenerCategorias();
        return ResponseEntity.ok(categorias);
    }

    /**
     * Metodo GET que llama al servicio para obtener una categoria por su ID.
     *
     * @param id ID de la categoria a obtener.
     * @return ResponseEntity con la categoria encontrada y el estado HTTP 200 (OK).
     */
    @GetMapping("/{id}")
    public ResponseEntity<Categoria> obtenerCategoriaPorId(@PathVariable Long id) {
        Categoria categoria = categoriaService.obtenerCategoriaPorId(id);
        return ResponseEntity.ok(categoria);
    }

    /**
     * Metodo POST que llama al servicio para crear una nueva categoria.
     *
     * @param categoriaRequest DTO con los datos de la categoria a crear.
     * @return ResponseEntity con la categoria creada y el estado HTTP 201 (CREATED).
     */
    @PostMapping("/add")
    public ResponseEntity<Categoria> crearCategoria(@Valid @RequestBody CategoriaRequest categoriaRequest) {
        Categoria categoriaNueva = categoriaService.crearCategoria(CategoriaMapper.convertirAEntidad(categoriaRequest));
        return ResponseEntity.status(HttpStatus.CREATED).body(categoriaNueva);
    }

    /**
     * Metodo DELETE que llama al servicio para eliminar una categoria por su ID.
     *
     * @param id ID de la categoria a eliminar.
     * @return ResponseEntity con el estado HTTP 204 (NO CONTENT).
     */
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> eliminarCategoria(@PathVariable Long id) {
        categoriaService.eliminarCategoria(id);
        return  ResponseEntity.noContent().build();
    }

    /**
     * Metodo PUT que llama al servicio para actualizar una categoria por su ID.
     *
     * @param id ID de la categoria a actualizar.
     * @param categoriaRequest DTO con los datos de la categoria a actualizar.
     * @return ResponseEntity con la categoria actualizada y el estado HTTP 200 (OK).
     */
    @PutMapping("/update/{id}")
    public ResponseEntity<Categoria> actualizarCategoria(@PathVariable Long id, @Valid @RequestBody CategoriaRequest categoriaRequest) {
        Categoria categoriaActualizado = categoriaService.actualizarCategoria(id, CategoriaMapper.convertirAEntidad(categoriaRequest));
        return ResponseEntity.ok(categoriaActualizado);
    }
}