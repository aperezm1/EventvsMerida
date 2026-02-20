package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.repository.UsuarioRepository;
import jakarta.persistence.NoResultException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.NoSuchElementException;

/**
 * Servicio para gestionar la logica de negocio relacionada con la
 * entidad Usuario.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RequiredArgsConstructor
@Service
public class UsuarioService {
    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * Metodo para obtener todos los usuarios.
     *
     * @return Lista de usuarios.
     */
    public List<Usuario> obtenerUsuarios() {
        List<Usuario> usuarios = usuarioRepository.findAll();

        if (usuarios.isEmpty()) {
            throw new NoResultException("Error en UsuarioService.obtenerUsuarios: No se encontraron usuarios en la base de datos");
        }

        return usuarios;
    }

    /**
     * Metodo para obtener un usuario por su ID.
     *
     * @param id ID del usuario a obtener.
     * @return Usuario encontrado.
     */
    public Usuario obtenerUsuarioPorId(Long id) {
        return obtenerUsuarioPorIdOExcepcion(id, "Error en UsuarioService.obtenerUsuarioPorId: No se encontró el usuario con id " + id);
    }

    /**
     * Metodo para crear un nuevo usuario.
     *
     * @param usuarioNuevo Datos del usuario a crear.
     * @return Usuario creado.
     */
    public Usuario crearUsuario(Usuario usuarioNuevo) {
        usuarioNuevo.setPassword(passwordEncoder.encode(usuarioNuevo.getPassword()));
        return usuarioRepository.save(usuarioNuevo);
    }

    /**
     * Metodo para eliminar un usuario por su ID.
     *
     * @param id ID del usuario a eliminar.
     */
    public void eliminarUsuario(Long id) {
        if (!usuarioRepository.existsById(id)) {
            throw new NoSuchElementException("Error en UsuarioService.eliminarUsuario: No se encontró el usuario con id " + id);
        }
        usuarioRepository.deleteById(id);
    }

    /**
     * Metodo para actualizar un usuario existente.
     *
     * @param id ID del usuario a actualizar.
     * @param usuarioAActualizar Datos actualizados del usuario.
     * @return Usuario actualizado.
     */
    public Usuario actualizarUsuario(Long id, Usuario usuarioAActualizar) {
        Usuario usuarioExistente = obtenerUsuarioPorIdOExcepcion(id, "No se encontró el usuario con id " + id);

        if (usuarioAActualizar.getNombre() != null)
            usuarioExistente.setNombre(usuarioAActualizar.getNombre());
        if (usuarioAActualizar.getApellidos() != null)
            usuarioExistente.setApellidos(usuarioAActualizar.getApellidos());
        if (usuarioAActualizar.getFechaNacimiento() != null)
            usuarioExistente.setFechaNacimiento(usuarioAActualizar.getFechaNacimiento());
        if (usuarioAActualizar.getEmail() != null)
            usuarioExistente.setEmail(usuarioAActualizar.getEmail());
        if (usuarioAActualizar.getTelefono() != null)
            usuarioExistente.setTelefono(usuarioAActualizar.getTelefono());
        if (usuarioAActualizar.getPassword() != null)
            usuarioExistente.setPassword(passwordEncoder.encode(usuarioAActualizar.getPassword()));
        if (usuarioAActualizar.getIdRol() != null)
            usuarioExistente.setIdRol(usuarioAActualizar.getIdRol());

        return usuarioRepository.save(usuarioExistente);
    }

    // =================
    // Metodos de Lógica
    // =================

    /**
     * Metodo para iniciar sesión a un usuario con su email y contraseña.
     *
     * @param email Email del usuario a autenticar.
     * @param password Contraseña del usuario a autenticar.
     * @return Usuario logeado si las credenciales son correctas.
     */
    public Usuario login(String email, String password) {
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new NoSuchElementException("Error en UsuarioService.login: No se encontró el usuario con email " + email));

        if (!passwordEncoder.matches(password, usuario.getPassword())) {
            throw new DataIntegrityViolationException("Credenciales inválidas");
        }

        log.info("Login exitoso para el usuario con email: {}", email);
        return usuario;
    }

    // ================
    // Metodos Privados
    // ================

    /**
     * Metodo privado para obtener un usuario por su ID o lanzar una excepcion
     * personalizada si no se encuentra.
     *
     * @param id ID del usuario a obtener.
     * @param mensajeError Mensaje de error para la excepcion.
     * @return Usuario encontrado.
     */
    private Usuario obtenerUsuarioPorIdOExcepcion(Long id, String mensajeError) {
        return usuarioRepository.findById(id).orElseThrow(() -> new NoSuchElementException(mensajeError));
    }
}