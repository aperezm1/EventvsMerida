package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.RolRequest;
import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.service.RolService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST que recibe las peticiones HTTP relacionadas con la
 * entidad Rol y las delega al servicio correspondiente.
 */
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/roles")
public class RolController {
    private final RolService rolService;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Metodo GET que llama al servicio para obtener todos los roles.
     *
     * @return ResponseEntity con la lista de roles y el estado HTTP 200 (OK).
     */
    @GetMapping("/all")
    public ResponseEntity<List<Rol>> obtenerRoles() {
        List<Rol> roles = rolService.obtenerRoles();
        return ResponseEntity.ok(roles);
    }

    /**
     * Metodo GET que llama al servicio para obtener un rol por su ID.
     *
     * @param id ID del rol a obtener.
     * @return ResponseEntity con el rol encontrado y el estado HTTP 200 (OK).
     */
    @GetMapping("/{id}")
    public ResponseEntity<Rol> obtenerRolPorId(@PathVariable Long id) {
        Rol rol = rolService.obtenerRolPorId(id);
        return ResponseEntity.ok(rol);
    }

    /**
     * Metodo POST que llama al servicio para crear un nuevo rol.
     *
     * @param rolRequest Datos del rol a crear.
     * @return ResponseEntity con el rol creado y el estado HTTP 201 (CREATED).
     */
    @PostMapping("/add")
    public ResponseEntity<Rol> crearRol(@Valid @RequestBody RolRequest rolRequest) {
        Rol rolNuevo = rolService.crearRol(obtenerRolConNombreCapitalizado(rolRequest));
        return ResponseEntity.status(HttpStatus.CREATED).body(rolNuevo);
    }

    /**
     * Metodo DELETE que llama al servicio para eliminar un rol por su ID.
     *
     * @param id ID del rol a eliminar.
     * @return ResponseEntity con el estado HTTP 204 (NO CONTENT).
     */
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> eliminarRol(@PathVariable Long id) {
        rolService.eliminarRol(id);
        return ResponseEntity.noContent().build(); // 204
    }

    /**
     * Metodo PUT que llama al servicio para actualizar un rol existente.
     *
     * @param id ID del rol a actualizar.
     * @param rolRequest Datos actualizados del rol.
     * @return ResponseEntity con el rol actualizado y el estado HTTP 200 (OK).
     */
    @PutMapping("/update/{id}")
    public ResponseEntity<Rol> actualizarRol(@PathVariable Long id, @Valid @RequestBody RolRequest rolRequest) {
        Rol rolActualizado = rolService.actualizarRol(id, obtenerRolConNombreCapitalizado(rolRequest));
        return ResponseEntity.ok(rolActualizado);
    }

    // ================
    // Metodos Privados
    // ================

    /**
     * Metodo privado para obtener un objeto Rol con el nombre capitalizado.
     *
     * @param rolRequest Datos del rol.
     * @return Objeto Rol con el nombre capitalizado.
     */
    private Rol obtenerRolConNombreCapitalizado(RolRequest rolRequest) {
        String nuevoNombre = rolRequest.getNombre().trim();
        String nombreCapitalizado = nuevoNombre.substring(0, 1).toUpperCase() + nuevoNombre.substring(1).toLowerCase();
        return new Rol(null, nombreCapitalizado);
    }
}