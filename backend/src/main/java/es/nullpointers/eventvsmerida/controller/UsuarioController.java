package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.UsuarioRequest;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.service.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST que recibe las peticiones HTTP relacionadas con la
 * entidad Usuario y las delega al servicio correspondiente.
 */
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/usuarios")
public class UsuarioController {
    private final UsuarioService usuarioService;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Metodo GET que llama al servicio para obtener todos los usuarios.
     *
     * @return ResponseEntity con la lista de usuarios y el estado HTTP 200 (OK).
     */
    @GetMapping("/all")
    public ResponseEntity<List<Usuario>> obtenerUsuarios() {
        List<Usuario> usuarios = usuarioService.obtenerUsuarios();
        return ResponseEntity.ok(usuarios);
    }

    /**
     * Metodo GET que llama al servicio para obtener un usuario por su ID.
     *
     * @param id ID del usuario a obtener.
     * @return ResponseEntity con el usuario encontrado y el estado HTTP 200 (OK).
     */
    @GetMapping("/{id}")
    public ResponseEntity<Usuario> obtenerUsuarioPorId(@PathVariable Long id) {
        Usuario usuario = usuarioService.obtenerUsuarioPorId(id);
        return ResponseEntity.ok(usuario);
    }

    /**
     * Metodo POST que llama al servicio para crear un nuevo usuario.
     *
     * @param usuarioRequest Datos del usuario a crear.
     * @return ResponseEntity con el usuario creado y el estado HTTP 201 (CREATED).
     */
//    @PostMapping("/add")
//    public ResponseEntity<Usuario> crearUsuario(@Valid @RequestBody UsuarioRequest usuarioRequest) {
//        Usuario usuarioNuevo = usuarioService.crearUsuario();
//        return ResponseEntity.status(HttpStatus.CREATED).body(usuarioNuevo);
//    }

    /**
     * Metodo DELETE que llama al servicio para eliminar un usuario por su ID.
     *
     * @param id ID del usuario a eliminar.
     * @return ResponseEntity con el estado HTTP 204 (NO CONTENT).
     */
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> eliminarUsuario(@PathVariable Long id) {
        usuarioService.eliminarUsuario(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Metodo PUT que llama al servicio para actualizar un usuario existente.
     *
     * @param id ID del usuario a actualizar.
     * @param usuarioRequest Datos actualizados del usuario.
     * @return ResponseEntity con el usuario actualizado y el estado HTTP 200 (OK).
     */
//    @PutMapping("/update/{id}")
//    public ResponseEntity<Usuario> actualizarUsuario(@PathVariable Long id, @Valid @RequestBody UsuarioRequest usuarioRequest) {
//        Usuario usuarioActualizado = usuarioService.actualizarRol(id, );
//        return ResponseEntity.ok(usuarioActualizado);
//    }

    // ================
    // Metodos Privados
    // ================

    private Usuario obtenerUsuarioConTextosValidos(UsuarioRequest usuarioRequest) {
        Usuario usuario = new Usuario();
        usuario.setNombre(usuarioRequest.getNombre().trim());
        usuario.setEmail(usuarioRequest.getEmail().trim().toLowerCase());
        return usuario;
    }
}