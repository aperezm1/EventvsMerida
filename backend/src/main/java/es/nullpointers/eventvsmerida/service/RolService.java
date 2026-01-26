package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.repository.RolRepository;
import jakarta.persistence.NoResultException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.NoSuchElementException;

@Slf4j
@RequiredArgsConstructor
@Service
public class RolService {
    private final RolRepository rolRepository;

    // ============
    // Metodos CRUD
    // ============

    public List<Rol> obtenerRoles() {
        List<Rol> roles = rolRepository.findAll();

        if (roles.isEmpty()) {
            throw new NoResultException("Error en RolService.obtenerRoles: No se encontraron roles en la base de datos");
        }

        return roles;
    }

    public Rol obtenerRolPorId(Long id) {
        return rolRepository.findById(id).orElseThrow(() -> new NoSuchElementException("Error en RolService.obtenerRolPorId: No se encontró el rol con id " + id));
    }

    public Rol crearRol(Rol rol) {
        return rolRepository.save(rol);
    }
}
