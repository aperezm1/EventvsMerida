package es.nullpointers.eventvsmerida.mapper;

import es.nullpointers.eventvsmerida.dto.RolRequest;
import es.nullpointers.eventvsmerida.entity.Rol;
import es.nullpointers.eventvsmerida.utils.TextoUtils;

/**
 * Clase mapper que convierte entre objetos DTO y entidades
 * relacionadas con la entidad Rol.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public class RolMapper {

    /**
     * Metodo que convierte un objeto RolRequest a una entidad Rol,
     * capitalizando el nombre del rol.
     *
     * @param request Objeto DTO con los datos del rol.
     * @return Entidad Rol creada a partir del DTO.
     */
    public static Rol convertirAEntidad(RolRequest request) {
        Rol rol = new Rol();
        rol.setNombre(TextoUtils.capitalizarTexto(request.getNombre()));
        return rol;
    }
}