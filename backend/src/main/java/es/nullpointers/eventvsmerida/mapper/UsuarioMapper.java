package es.nullpointers.eventvsmerida.mapper;

import es.nullpointers.eventvsmerida.dto.UsuarioBaseRequest;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.service.RolService;
import es.nullpointers.eventvsmerida.utils.TextoUtils;

/**
 * Clase mapper que convierte entre objetos DTO y entidades
 * relacionadas con la entidad Usuario.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public class UsuarioMapper {

    /**
     * Metodo que convierte un objeto UsuarioBaseRequest a una entidad Usuario,
     * capitalizando y normalizando los campos de texto.
     *
     * @param request Objeto DTO con los datos del usuario.
     * @param rolService Servicio para obtener el rol por ID.
     * @return Entidad Usuario creada a partir del DTO.
     */
    public static Usuario convertirAEntidad(UsuarioBaseRequest request, RolService rolService) {
        Usuario usuario = new Usuario();

        usuario.setNombre(TextoUtils.capitalizarTexto(request.getNombre()));
        usuario.setApellidos(TextoUtils.capitalizarTexto(request.getApellidos()));
        usuario.setFechaNacimiento(request.getFechaNacimiento());
        usuario.setEmail(TextoUtils.normalizarTexto(request.getEmail()));
        usuario.setTelefono(request.getTelefono());
        usuario.setPassword(request.getPassword().trim());

        if (request.getIdRol() != null)
            usuario.setIdRol(rolService.obtenerRolPorId(request.getIdRol()));

        return usuario;
    }
}