package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.entity.PasswordResetToken;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.repository.PasswordResetTokenRepository;
import es.nullpointers.eventvsmerida.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

/**
 * Servicio encargado de gestionar la del proceso de restablecimiento de contraseña.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Slf4j
@RequiredArgsConstructor
@Service
public class AuthService {
    final PasswordResetTokenRepository tokenRepository;
    final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    public String resetPassword(String token, String nuevaPassword) {

        PasswordResetToken resetToken =
                tokenRepository.findByToken(token);

        if (resetToken == null) {
            return "INVALID_TOKEN";
        }

        if (Boolean.TRUE.equals(resetToken.getUsado())) {
            return "USED_TOKEN";
        }

        // Comprobar expiración
        if (resetToken.getExpiracion().isBefore(LocalDateTime.now())) {
            return "EXPIRED_TOKEN";
        }

        Usuario usuario = resetToken.getUsuario();

        if (usuario == null) {
            return "Usuario no encontrado";
        }

        usuario.setPassword(
                passwordEncoder.encode(nuevaPassword)
        );

        usuarioRepository.save(usuario);

        resetToken.setUsado(true);
        tokenRepository.save(resetToken);

        return "Contraseña actualizada correctamente";
    }
}
