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

@Slf4j
@RequiredArgsConstructor
@Service
public class AuthService {
    final PasswordResetTokenRepository tokenRepository;
    final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    public String resetPassword(String token, String nuevaPassword) {

        // 1. Buscar token en BD
        PasswordResetToken resetToken =
                tokenRepository.findByToken(token);

        if (resetToken == null) {
            return "INVALID_TOKEN";
        }

        // 2. Comprobar si ya fue usado
        if (Boolean.TRUE.equals(resetToken.getUsado())) {
            return "USED_TOKEN";
        }

        // 3. Comprobar expiración
        if (resetToken.getExpiracion().isBefore(LocalDateTime.now())) {
            return "EXPIRED_TOKEN";
        }

        // 4. Obtener usuario
        Usuario usuario = resetToken.getUsuario();

        if (usuario == null) {
            return "Usuario no encontrado";
        }

        // 5. Cambiar contraseña (IMPORTANTE: encriptada)
        usuario.setPassword(
                passwordEncoder.encode(nuevaPassword)
        );

        usuarioRepository.save(usuario);

        // 6. Marcar token como usado (mejor que borrarlo)
        resetToken.setUsado(true);
        tokenRepository.save(resetToken);

        return "Contraseña actualizada correctamente";
    }
}
