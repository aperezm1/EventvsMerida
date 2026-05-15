package es.nullpointers.eventvsmerida.service;

import es.nullpointers.eventvsmerida.entity.PasswordResetToken;
import es.nullpointers.eventvsmerida.entity.RefreshToken;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.repository.PasswordResetTokenRepository;
import es.nullpointers.eventvsmerida.repository.RefreshTokenRepository;
import es.nullpointers.eventvsmerida.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * Servicio encargado de gestionar el proceso de restablecimiento de contraseña
 * y la gestión de refresh tokens para sesiones en dispositivos móviles.
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
    final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * Restablece la contraseña de un usuario utilizando un token de
     * restablecimiento.
     *
     * @param token         El token de restablecimiento de contraseña enviado al
     *                      correo del usuario.
     * @param nuevaPassword La nueva contraseña que el usuario desea establecer.
     * @return Un mensaje indicando el resultado del proceso de restablecimiento de
     *         contraseña.
     */
    public String resetPassword(String token, String nuevaPassword) {
        PasswordResetToken resetToken = tokenRepository.findByToken(token);

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

        usuario.setPassword(passwordEncoder.encode(nuevaPassword));

        usuarioRepository.save(usuario);

        resetToken.setUsado(true);
        tokenRepository.save(resetToken);

        return "Contraseña actualizada correctamente";
    }

    /**
     * Crea un nuevo refresh token para el usuario especificado, revocando cualquier
     * token anterior no revocado.
     * 
     * @param usuario El usuario para el cual se va a crear el refresh token.
     * @param ttl     La duración del refresh token antes de su expiración.
     * @return El token de refresh generado para el usuario.
     */
    public String crearRefreshToken(Usuario usuario, Duration ttl) {
        revocarTokensUsuario(usuario);
        return crearRefreshTokenInterno(usuario, ttl);
    }

    /**
     * Valida un refresh token verificando su existencia, estado de revocación y
     * fecha de expiración.
     *
     * @param token El token de refresh que se desea validar.
     * @return El objeto RefreshToken si es válido, o null si el token es inválido,
     *         revocado o expirado.
     */
    public RefreshToken validarRefreshToken(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }

        RefreshToken refreshToken = refreshTokenRepository.findByToken(token);

        if (refreshToken == null) {
            return null;
        }

        if (Boolean.TRUE.equals(refreshToken.getRevocado())) {
            return null;
        }

        if (refreshToken.getExpiracion().isBefore(LocalDateTime.now())) {
            return null;
        }

        return refreshToken;
    }

    /**
     * Revoca un refresh token específico y genera uno nuevo para el mismo usuario.
     *
     * @param refreshToken El refresh token que se desea rotar (revocar y
     *                     reemplazar).
     * @param ttl          La duración del nuevo refresh token antes de su
     *                     expiración.
     * @return El nuevo token de refresh generado para el usuario después de revocar
     *         el token anterior.
     */
    public String rotarRefreshToken(RefreshToken refreshToken, Duration ttl) {
        refreshToken.setRevocado(true);
        refreshTokenRepository.save(refreshToken);
        return crearRefreshTokenInterno(refreshToken.getUsuario(), ttl);
    }

    /**
     * Revoca todos los refresh tokens no revocados asociados a un usuario
     * específico, marcándolos como revocados en la base de datos.
     *
     * @param usuario El usuario para el cual se desean revocar todos los refresh
     *                tokens activos (no revocados).
     */
    public void revocarTokensUsuario(Usuario usuario) {
        var tokens = refreshTokenRepository.findAllByUsuarioAndRevocadoFalse(usuario);

        for (RefreshToken token : tokens) {
            token.setRevocado(true);
        }

        refreshTokenRepository.saveAll(tokens);
    }

    /**
     * Crea un nuevo refresh token para un usuario específico con una duración
     * determinada, sin revocar tokens anteriores.
     *
     * @param usuario El usuario para el cual se va a crear el refresh token.
     * @param ttl     La duración del refresh token antes de su expiración.
     * @return El token de refresh generado para el usuario.
     */
    private String crearRefreshTokenInterno(Usuario usuario, Duration ttl) {
        RefreshToken refreshToken = new RefreshToken();
        refreshToken.setToken(java.util.UUID.randomUUID().toString());
        refreshToken.setExpiracion(LocalDateTime.now().plus(ttl));
        refreshToken.setUsuario(usuario);
        refreshToken.setRevocado(false);

        refreshTokenRepository.save(refreshToken);
        return refreshToken.getToken();
    }
}