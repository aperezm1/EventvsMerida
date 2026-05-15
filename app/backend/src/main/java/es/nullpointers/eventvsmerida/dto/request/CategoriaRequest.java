package es.nullpointers.eventvsmerida.dto.request;

import jakarta.validation.constraints.NotBlank;

/**
 * DTO para la creación o actualización de una categoría.
 *
 * @param nombre nombre de la categoría. No puede estar vacío ni contener solo
 *               espacios.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public record CategoriaRequest(
        @NotBlank String nombre
) {}