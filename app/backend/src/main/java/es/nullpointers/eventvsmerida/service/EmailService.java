package es.nullpointers.eventvsmerida.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class EmailService {

    @Value("${mailjet.api-key}")
    private String apiKey;

    @Value("${mailjet.secret-key}")
    private String secretKey;

    @Value("${mailjet.from-email}")
    private String fromEmail;

    @Value("${mailjet.from-name}")
    private String fromName;

    @Value("${app.recover-url}")
    private String recoverUrl;

    public void enviarCorreoRecuperacion(String destinatario, String token) {
        String basicAuth = Base64.getEncoder()
                .encodeToString((apiKey.trim() + ":" + secretKey.trim()).getBytes(StandardCharsets.UTF_8));

        RestClient client = RestClient.builder()
                .baseUrl("https://api.mailjet.com/v3.1")
                .defaultHeader(HttpHeaders.AUTHORIZATION, "Basic " + basicAuth)
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();

        String urlRecuperacion = recoverUrl + "?token=" + token;

        Map<String, Object> body = Map.of(
                "Messages", List.of(
                        Map.of(
                                "From", Map.of(
                                        "Email", fromEmail,
                                        "Name", fromName
                                ),
                                "To", List.of(
                                        Map.of(
                                                "Email", destinatario,
                                                "Name", destinatario
                                        )
                                ),
                                "Subject", "Recuperación de contraseña - EventvsMerida",
                                "TextPart", "Has solicitado restablecer tu contraseña. Abre este enlace: " + urlRecuperacion,
                                "HTMLPart", """
                                        <html>
                                            <body>
                                                <h2>Recuperación de contraseña</h2>
                                                <p>Has solicitado restablecer tu contraseña.</p>
                                                <p>
                                                    %s
                                                        Restablecer contraseña
                                                    </a>
                                                </p>
                                                <p>Si no has solicitado este cambio, puedes ignorar este correo.</p>
                                            </body>
                                        </html>
                                        """.formatted(urlRecuperacion)
                        )
                )
        );

        client.post()
                .uri("/send")
                .body(body)
                .retrieve()
                .toBodilessEntity();
    }
}