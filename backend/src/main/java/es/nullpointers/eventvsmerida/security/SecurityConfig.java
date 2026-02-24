package es.nullpointers.eventvsmerida.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Configuración de seguridad para la aplicación.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Configuration
public class SecurityConfig {

    /**
     * Bean para el codificador de contraseñas utilizando BCrypt.
     *
     * @return un PasswordEncoder que utiliza BCrypt para codificar las contraseñas.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * Configura la cadena de filtros de seguridad para la aplicación.
     *
     * @param http el objeto HttpSecurity utilizado para configurar la seguridad HTTP.
     * @return un SecurityFilterChain que define las reglas de seguridad para las solicitudes HTTP.
     */
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/swagger-ui/**",
                                "/swagger-ui.html",
                                "/v3/api-docs/**"
                        ).hasAuthority("Administrador")
                        .anyRequest().permitAll()
                )
                .formLogin(Customizer.withDefaults());
        return http.build();
    }
}