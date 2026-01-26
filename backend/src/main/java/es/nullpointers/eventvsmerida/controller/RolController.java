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

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/roles")
public class RolController {
    private final RolService rolService;

    // ============
    // Metodos CRUD
    // ============

    @GetMapping("/all")
    public ResponseEntity<List<Rol>> obtenerRoles() {
        List<Rol> roles = rolService.obtenerRoles();
        return ResponseEntity.ok(roles);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Rol> obtenerRolPorId(@PathVariable Long id) {
        Rol rol = rolService.obtenerRolPorId(id);
        return ResponseEntity.ok(rol);
    }

    @PostMapping("/add")
    public ResponseEntity<Rol> crearRol(@Valid @RequestBody RolRequest rolRequest) {
        Rol rol = new Rol();
        rol.setNombre(rolRequest.getNombre());
        Rol guardado = rolService.crearRol(rol);
        return ResponseEntity.status(HttpStatus.CREATED).body(guardado);
    }
}