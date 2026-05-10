package es.nullpointers.eventvsmerida.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import java.time.LocalDate;
import java.time.Period;

/**
 * Validador personalizado para comprobar que la fecha de nacimiento
 * corresponde a una edad permitida dentro de la aplicación.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
public class EdadValidaValidator implements ConstraintValidator<EdadValida, LocalDate> {

    /**
     * Comprueba si la fecha de nacimiento cumple el rango de edad permitido.
     *
     * @param fechaNacimiento fecha de nacimiento que se va a validar.
     * @param context contexto de validación.
     * @return true si la fecha es null o si la edad está entre 14 y 100 años; false en caso contrario.
     */
    @Override
    public boolean isValid(LocalDate fechaNacimiento, ConstraintValidatorContext context) {
        if (fechaNacimiento == null) {
            return true;
        }

        int edad = Period.between(fechaNacimiento, LocalDate.now()).getYears();
        return edad >= 14 && edad <= 100;
    }
}