package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.repository.RolRepository;
import jakarta.persistence.NoResultException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.NoSuchElementException;

/**
 * Servicio para gestionar la logica de negocio relacionada con la
 * entidad Rol.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RequiredArgsConstructor
@Service
public class RolService {
    private final RolRepository rolRepository;

    // ============
    // Metodos CRUD
    // ============

    /**
     * Metodo para obtener todos los roles.
     *
     * @return Lista de roles.
     */
    public List<Rol> obtenerRoles() {
        List<Rol> roles = rolRepository.findAll();

        if (roles.isEmpty()) {
            throw new NoResultException("Error en RolService.obtenerRoles: No se encontraron roles en la base de datos");
        }

        return roles;
    }

    /**
     * Metodo para obtener un rol por su ID.
     *
     * @param id ID del rol a obtener.
     * @return Rol encontrado.
     */
    public Rol obtenerRolPorId(Long id) {
        return obtenerRolPorIdOExcepcion(id, "Error en RolService.obtenerRolPorId: No se encontró el rol con id " + id);
    }

    /**
     * Metodo para crear un nuevo rol.
     *
     * @param rolNuevo Datos del rol a crear.
     * @return Rol creado.
     */
    public Rol crearRol(Rol rolNuevo) {
        return rolRepository.save(rolNuevo);
    }

    /**
     * Metodo para eliminar un rol por su ID.
     *
     * @param id ID del rol a eliminar.
     */
    public void eliminarRol(Long id) {
        if (!rolRepository.existsById(id)) {
            throw new NoSuchElementException("Error en RolService.eliminarRol: No se encontró el rol con id " + id);
        }
        rolRepository.deleteById(id);
    }

    /**
     * Metodo para actualizar un rol existente.
     *
     * @param id ID del rol a actualizar.
     * @param rolAActualizar Datos actualizados del rol.
     * @return Rol actualizado.
     */
    public Rol actualizarRol(Long id, Rol rolAActualizar) {
        Rol rolExistente = obtenerRolPorIdOExcepcion(id, "Error en RolService.actualizarRol: No se encontró el rol con id: " + id);
        rolExistente.setNombre(rolAActualizar.getNombre());
        return rolRepository.save(rolExistente);
    }

    // ================
    // Metodos Privados
    // ================

    /**
     * Metodo privado para obtener un rol por su ID o lanzar una excepcion
     * personalizada si no se encuentra.
     *
     * @param id ID del rol a obtener.
     * @param mensajeError Mensaje de error para la excepcion.
     * @return Rol encontrado.
     */
    private Rol obtenerRolPorIdOExcepcion(Long id, String mensajeError) {
        return rolRepository.findById(id).orElseThrow(() -> new NoSuchElementException(mensajeError));
    }
}