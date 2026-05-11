package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.request.LoginRequest;
import es.nullpointers.eventvsmerida.dto.request.ResetPasswordRequest;
import es.nullpointers.eventvsmerida.dto.response.UsuarioResponse;
import es.nullpointers.eventvsmerida.entity.PasswordResetToken;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.repository.PasswordResetTokenRepository;
import es.nullpointers.eventvsmerida.repository.UsuarioRepository;
import es.nullpointers.eventvsmerida.service.AuthService;
import es.nullpointers.eventvsmerida.service.EmailService;
import es.nullpointers.eventvsmerida.service.UsuarioService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.AccessDeniedException;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Controlador REST que maneja las operaciones de autenticación, incluyendo inicio de sesión,
 * verificación de sesión activa y cierre de sesión.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/auth")
@Slf4j
public class AuthController {
    private final AuthenticationManager authenticationManager;
    private final UsuarioService usuarioService;
    private final UsuarioRepository usuarioRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final EmailService emailService;
    private final AuthService authService;

    /**
     * Endpoint para iniciar sesión. Si el parámetro "admin" es true, solo permitirá el acceso a usuarios con rol de administrador.
     *
     * @param loginRequest DTO con email y contraseña
     * @param admin indica si se requiere rol de administrador para el acceso
     * @param request objeto HttpServletRequest para gestionar la sesión
     * @return ResponseEntity con los datos del usuario logeado o error si no se cumplen las condiciones de autenticación/rol
     */
    @PostMapping("/login")
    public ResponseEntity<UsuarioResponse> login(
            @Valid @RequestBody LoginRequest loginRequest,
            @RequestParam(name = "admin", required = false, defaultValue = "false") boolean admin,
            HttpServletRequest request,
            HttpServletResponse response) {

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.email(), loginRequest.password())
        );

        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> "Administrador".equalsIgnoreCase(a.getAuthority()));

        if (admin && !isAdmin) {
            throw new AccessDeniedException("Solo administradores pueden iniciar sesión");
        }

        SecurityContext context = SecurityContextHolder.createEmptyContext();
        context.setAuthentication(authentication);
        SecurityContextHolder.setContext(context);

        new HttpSessionSecurityContextRepository().saveContext(context, request, response);

        UsuarioResponse usuarioLogeado = usuarioService.obtenerUsuarioPorEmail(loginRequest.email());
        return ResponseEntity.ok(usuarioLogeado);
    }

    /**
     * Endpoint para verificar si el usuario tiene una sesión activa. Retorna 200 OK si el usuario está autenticado, o 401 UNAUTHORIZED si no lo está.
     *
     * @param authentication objeto Authentication inyectado por Spring Security, representa la autenticación actual del usuario
     * @return ResponseEntity sin cuerpo, con estado 200 OK si el usuario está autenticado o 401 UNAUTHORIZED si no lo está
     */
    @GetMapping("/session")
    public ResponseEntity<Void> session(Authentication authentication) {
        if (authentication == null
                || authentication instanceof AnonymousAuthenticationToken
                || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok().build();
    }

    /**
     * Endpoint para cerrar sesión. Limpia el contexto de seguridad e invalida la sesión HTTP.
     *
     * @param request objeto HttpServletRequest para gestionar la sesión
     * @return ResponseEntity sin cuerpo, con estado 204 NO CONTENT después de cerrar sesión exitosamente
     */
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpServletRequest request) {
        SecurityContextHolder.clearContext();
        var session = request.getSession(false);
        if (session != null) session.invalidate();
        return ResponseEntity.noContent().build();
    }

    /**
     * Endpoint para recuperar contraseña a través del correo electrónico. Genera un token de recuperación, lo guarda en la base de datos y envía un correo al usuario con el enlace para restablecer su contraseña.
     *
     * @param email Correo electrónico del usuario que ha olvidado su contraseña
     * @return ResponseEntity con mensaje de connfirmación de envío del correo o error si el usuario no se encuentra.
     */
    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@RequestParam String email) {

        Optional<Usuario> usuario = usuarioRepository.findByEmail(email);

        if (usuario == null) {
            return ResponseEntity.badRequest().body("Usuario no encontrado");
        }

        String token = UUID.randomUUID().toString();

        PasswordResetToken resetToken = new PasswordResetToken();
        resetToken.setToken(token);
        resetToken.setUsuario(usuario.get());
        resetToken.setExpiracion(LocalDateTime.now().plusMinutes(30));

        tokenRepository.save(resetToken);

        emailService.enviarCorreoRecuperacion(
                usuario.get().getEmail(),
                token,
                usuario.get().getNombre()
        );

        return ResponseEntity.ok("Correo enviado");
    }

    /**
     * Endpoint para establecer una nueva contraseña utilizando el token de recuperación. Verifica que el token sea válido y no haya expirado, y luego actualiza la contraseña del usuario.
     *
     * @param request DTO de solicitud que contiene el token de recuperación y la nueva contraseña. La nueva contraseña debe cumplir con los requisitos de seguridad establecidos.
     * @return Devuelve un mensaje indicando el resultado de la operación, como "Contraseña actualizada correctamente" o errores específicos como "TOKEN inválido".
     */
    @PostMapping("/reset-password")
    public String resetPassword(
            @RequestBody ResetPasswordRequest request) {

        return authService.resetPassword(
                request.token(),
                request.nuevaPassword()
        );
    }
}