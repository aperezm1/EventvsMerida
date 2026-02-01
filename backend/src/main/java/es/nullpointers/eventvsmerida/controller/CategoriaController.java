package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.CategoriaRequest;
import es.nullpointers.eventvsmerida.entity.Categoria;
import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.service.CategoriaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/categorias")
public class CategoriaController {
    private final CategoriaService categoriaService;

    // ============
    // Metodos CRUD
    // ============

    @GetMapping("/all")
    public ResponseEntity<List<Categoria>> obtenerCategorias() {
        List<Categoria> categorias = categoriaService.obtenerCategorias();
        return ResponseEntity.ok(categorias);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Categoria> obtenerCategoriaPorId(@PathVariable Long id) {
        Categoria categoria = categoriaService.obtenerCategoriaPorId(id);
        return ResponseEntity.ok(categoria);
    }

    @PostMapping("/add")
    public ResponseEntity<Categoria> crearCategoria(@Valid @RequestBody CategoriaRequest categoriaRequest) {
        Categoria categoriaNueva = categoriaService.crearCategoria(obtenerCategoriaConNombreCapitalizado(categoriaRequest));
        return ResponseEntity.status(HttpStatus.CREATED).body(categoriaNueva);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> eliminarCategoria(@PathVariable Long id) {
        categoriaService.eliminarCategoria(id);
        return  ResponseEntity.noContent().build();
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<Categoria> actualizarCategoria(@PathVariable Long id, @Valid @RequestBody CategoriaRequest categoriaRequest) {
        Categoria categoriaActualizado = categoriaService.actualizarCategoria(id, obtenerCategoriaConNombreCapitalizado(categoriaRequest));
        return ResponseEntity.ok(categoriaActualizado);
    }

    // ================
    // Metodos Privados
    // ================

    private Categoria obtenerCategoriaConNombreCapitalizado(CategoriaRequest categoriaRequest) {
        String nuevoNombre = categoriaRequest.getNombre().trim();
        String nombreCapitalizado = nuevoNombre.substring(0, 1).toUpperCase() + nuevoNombre.substring(1).toLowerCase();
        return new Categoria(null, nombreCapitalizado);
    }
}

