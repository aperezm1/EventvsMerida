package es.nullpointers.eventvsmerida.controller;

import es.nullpointers.eventvsmerida.dto.request.LoginRequest;
import es.nullpointers.eventvsmerida.dto.request.RefreshTokenRequest;
import es.nullpointers.eventvsmerida.dto.request.ResetPasswordRequest;
import es.nullpointers.eventvsmerida.dto.response.UsuarioResponse;
import es.nullpointers.eventvsmerida.entity.PasswordResetToken;
import es.nullpointers.eventvsmerida.entity.RefreshToken;
import es.nullpointers.eventvsmerida.entity.Usuario;
import es.nullpointers.eventvsmerida.repository.PasswordResetTokenRepository;
import es.nullpointers.eventvsmerida.repository.UsuarioRepository;
import es.nullpointers.eventvsmerida.service.AuthService;
import es.nullpointers.eventvsmerida.service.EmailService;
import es.nullpointers.eventvsmerida.service.UsuarioService;
import es.nullpointers.eventvsmerida.security.CustomUserDetailsService;
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

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Controlador REST que maneja las operaciones de autenticación, incluyendo
 * inicio de sesión, verificación de sesión activa y cierre de sesión.
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
    private final CustomUserDetailsService userDetailsService;

    /**
     * Endpoint para iniciar sesión. Autentica al usuario utilizando el email y la
     * contraseña proporcionados en el cuerpo de la solicitud.
     * Si la autenticación es exitosa, se establece el contexto de seguridad y se
     * devuelve la información del usuario logeado.
     * 
     * @param loginRequest DTO de solicitud que contiene el email y la contraseña
     *                     del usuario.
     * @param admin        Parámetro opcional que indica si se requiere que el
     *                     usuario tenga rol de administrador para iniciar sesión.
     *                     Si es true, solo los usuarios con rol de administrador
     *                     podrán autenticarse.
     * @param rememberMe   Parámetro opcional que indica si se debe generar un
     *                     refresh token para mantener la sesión activa durante un
     *                     período prolongado. Si es true y el usuario tiene rol de
     *                     administrador u organizador, se generará un refresh token
     *                     válido por 60 días y se incluirá en la cabecera de la
     *                     respuesta.
     * @param request      objeto HttpServletRequest para gestionar la sesión y el
     *                     contexto de seguridad.
     * @param response     objeto HttpServletResponse para agregar el refresh token
     *                     en la cabecera de la respuesta si se genera uno.
     * @return ResponseEntity con la información del usuario logeado en el cuerpo de
     *         la respuesta y un refresh token en la cabecera "X-Refresh-Token" si
     *         se generó uno. Retorna 200 OK si la autenticación fue exitosa, o 401
     *         UNAUTHORIZED si las credenciales son inválidas, o 403 FORBIDDEN si se
     *         requiere rol de administrador y el usuario no lo tiene.
     */
    @PostMapping("/login")
    public ResponseEntity<UsuarioResponse> login(
            @Valid @RequestBody LoginRequest loginRequest,
            @RequestParam(name = "admin", required = false, defaultValue = "false") boolean admin,
            @RequestParam(name = "rememberMe", required = false, defaultValue = "false") boolean rememberMe,
            HttpServletRequest request,
            HttpServletResponse response) {

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.email(), loginRequest.password()));

        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> "Administrador".equalsIgnoreCase(a.getAuthority()));
        boolean isOrganizer = authentication.getAuthorities().stream()
                .anyMatch(a -> "Organizador".equalsIgnoreCase(a.getAuthority()));

        if (admin && !isAdmin) {
            throw new AccessDeniedException("Solo administradores pueden iniciar sesión");
        }

        SecurityContext context = SecurityContextHolder.createEmptyContext();
        context.setAuthentication(authentication);
        SecurityContextHolder.setContext(context);

        new HttpSessionSecurityContextRepository().saveContext(context, request, response);

        UsuarioResponse usuarioLogeado = usuarioService.obtenerUsuarioPorEmail(loginRequest.email());
        var respuesta = ResponseEntity.ok();

        if (rememberMe && (isAdmin || isOrganizer)) {
            Usuario usuario = usuarioRepository.findByEmail(loginRequest.email()).orElse(null);

            if (usuario != null) {
                String refreshToken = authService.crearRefreshToken(usuario, Duration.ofDays(60));
                return respuesta.header("X-Refresh-Token", refreshToken).body(usuarioLogeado);
            }
        }

        return respuesta.body(usuarioLogeado);
    }

    /**
     * Endpoint para verificar si el usuario tiene una sesión activa. Retorna 200 OK
     * si el usuario está autenticado, o 401 UNAUTHORIZED si no lo está.
     *
     * @param authentication objeto Authentication inyectado por Spring Security,
     *                       representa la autenticación actual del usuario
     * @return ResponseEntity sin cuerpo, con estado 200 OK si el usuario está
     *         autenticado o 401 UNAUTHORIZED si no lo está
     */
    @GetMapping("/session")
    public ResponseEntity<Void> session(Authentication authentication) {
        if (authentication == null || authentication instanceof AnonymousAuthenticationToken
                || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        return ResponseEntity.ok().build();
    }

    /**
     * Endpoint para cerrar sesión. Limpia el contexto de seguridad y revoca los
     * tokens
     * 
     * @param request        objeto HttpServletRequest para gestionar la sesión y el
     *                       contexto de seguridad.
     * @param authentication objeto Authentication inyectado por Spring Security,
     *                       representa la autenticación actual del usuario
     * @return ResponseEntity sin cuerpo, con estado 204 NO CONTENT después de
     *         cerrar sesión exitosamente. Retorna 401 UNAUTHORIZED si el usuario no
     *         está autenticado.
     */
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpServletRequest request, Authentication authentication) {
        SecurityContextHolder.clearContext();
        var session = request.getSession(false);
        if (session != null)
            session.invalidate();

        if (authentication != null && !(authentication instanceof AnonymousAuthenticationToken)
                && authentication.isAuthenticated()) {
            Usuario usuario = usuarioRepository.findByEmail(authentication.getName()).orElse(null);

            if (usuario != null) {
                authService.revocarTokensUsuario(usuario);
            }
        }

        return ResponseEntity.noContent().build();
    }

    /**
     * Endpoint para recuperar contraseña a través del correo electrónico. Genera un
     * token de recuperación, lo guarda en la base de datos y envía un correo al
     * usuario con el enlace para restablecer su contraseña.
     *
     * @param email Correo electrónico del usuario que ha olvidado su contraseña
     * @return ResponseEntity con mensaje de confirmación de envío del correo o
     *         error si el usuario no se encuentra.
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
                resetToken.getToken(),
                usuario.get().getNombre());

        return ResponseEntity.ok("Correo enviado");
    }

    /**
     * Endpoint para establecer una nueva contraseña utilizando el token de
     * recuperación. Verifica que el token sea válido y no haya expirado, y luego
     * actualiza la contraseña del usuario.
     *
     * @param request DTO de solicitud que contiene el token de recuperación y la
     *                nueva contraseña. La nueva contraseña debe cumplir con los
     *                requisitos de seguridad establecidos.
     * @return Devuelve un mensaje indicando el resultado de la operación, como
     *         "Contraseña actualizada correctamente" o errores específicos como
     *         "TOKEN inválido".
     */
    @PostMapping("/reset-password")
    public String resetPassword(@RequestBody ResetPasswordRequest request) {

        return authService.resetPassword(
                request.token(),
                request.nuevaPassword());
    }

    /**
     * Endpoint para refrescar el token de autenticación utilizando un refresh token
     * válido.
     * Verifica el refresh token, autentica al usuario asociado y genera un nuevo
     * refresh token, devolviéndolo en la cabecera de la respuesta.
     *
     * @param refreshRequest DTO de solicitud que contiene el refresh token a
     *                       validar. El token debe ser válido, no revocado y no
     *                       haber expirado para que se genere un nuevo token.
     * @param request        objeto HttpServletRequest para gestionar la sesión y el
     *                       contexto de seguridad.
     * @param response       objeto HttpServletResponse para agregar el nuevo
     *                       refresh token en la cabecera de la respuesta.
     * @return ResponseEntity sin cuerpo, con estado 200 OK y un nuevo refresh token
     *         en la cabecera "X-Refresh-Token" si el token de refresco es válido, o
     *         401 UNAUTHORIZED si el token es inválido o el usuario no se
     *         encuentra.
     */
    @PostMapping("/refresh")
    public ResponseEntity<Void> refresh(@Valid @RequestBody RefreshTokenRequest refreshRequest,
            HttpServletRequest request, HttpServletResponse response) {
        RefreshToken refreshToken = authService.validarRefreshToken(refreshRequest.refreshToken());
        if (refreshToken == null || refreshToken.getUsuario() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        var userDetails = userDetailsService.loadUserByUsername(refreshToken.getUsuario().getEmail());
        Authentication authentication = new UsernamePasswordAuthenticationToken(
                userDetails,
                null,
                userDetails.getAuthorities());

        SecurityContext context = SecurityContextHolder.createEmptyContext();
        context.setAuthentication(authentication);
        SecurityContextHolder.setContext(context);
        new HttpSessionSecurityContextRepository().saveContext(context, request, response);

        String nuevoRefreshToken = authService.rotarRefreshToken(refreshToken, Duration.ofDays(60));
        return ResponseEntity.ok().header("X-Refresh-Token", nuevoRefreshToken).build();
    }
}