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

    public void enviarCorreoRecuperacion(String destinatario, String token, String nombreUsuario) {
        String basicAuth = Base64.getEncoder()
                .encodeToString((apiKey.trim() + ":" + secretKey.trim()).getBytes(StandardCharsets.UTF_8));

        RestClient client = RestClient.builder()
                .baseUrl("https://api.mailjet.com/v3.1")
                .defaultHeader(HttpHeaders.AUTHORIZATION, "Basic " + basicAuth)
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();

        String urlRecuperacion = recoverUrl + "?token=" + token;
        String nombreSeguro = (nombreUsuario == null || nombreUsuario.isBlank())
                ? ""
                : nombreUsuario.trim();
        String saludo = nombreSeguro.isEmpty()
                ? "¡Hola!"
                : "¡Hola, " + nombreSeguro + "!";
        String nombreDestinatario = nombreSeguro.isEmpty() ? destinatario : nombreSeguro;

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
                                                "Name", nombreDestinatario
                                        )
                                ),
                                "Subject", "Recuperación de contraseña - Eventvs Mérida",
                                "TextPart", saludo + " Has solicitado restablecer tu contraseña. Abre este enlace: " + urlRecuperacion,
                                "HTMLPart", """
                                         <!DOCTYPE html>
                                        <html>
                                            <head>
                                                <meta charset="UTF-8">
                                                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                                                <style>
                                                    body {
                                                        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                                                        margin: 0;
                                                        padding: 0;
                                                        background: #f2f7ff;
                                                    }
                                                    .container {
                                                        max-width: 600px;
                                                        margin: 20px auto;
                                                        background: #ffffff;
                                                        border-radius: 12px;
                                                        box-shadow: 0 10px 35px rgba(0, 0, 0, 0.1);
                                                        overflow: hidden;
                                                    }
                                                    .header {
                                                        background: #0074e8;
                                                        padding: 40px 20px;
                                                        text-align: center;
                                                        color: #ffffff;
                                                    }
                                                    .header h1 {
                                                        margin: 0;
                                                        font-size: 28px;
                                                        font-weight: 600;
                                                        letter-spacing: 0.5px;
                                                    }
                                                    .content {
                                                        padding: 40px 30px;
                                                    }
                                                    .content p {
                                                        color: #333333;
                                                        font-size: 15px;
                                                        line-height: 1.6;
                                                        margin: 15px 0;
                                                    }
                                                    .highlight {
                                                        color: #0074e8;
                                                        font-weight: 600;
                                                    }
                                                    .button-container {
                                                        text-align: center;
                                                        margin: 35px 0;
                                                    }
                                                    .button {
                                                        display: inline-block;
                                                        background: #ee8d24;
                                                        color: #ffffff !important;
                                                        padding: 14px 35px;
                                                        text-decoration: none !important;
                                                        border-radius: 8px;
                                                        font-weight: 600;
                                                        font-size: 15px;
                                                        transition: transform 0.2s ease, box-shadow 0.2s ease, background 0.2s ease;
                                                        box-shadow: 0 4px 15px rgba(238, 141, 36, 0.4);
                                                    }
                                                    .button:hover {
                                                        transform: translateY(-2px);
                                                        background: #0074e8;
                                                        box-shadow: 0 6px 20px rgba(0, 116, 232, 0.5);
                                                    }
                                                    .info-box {
                                                        background: #f8f9ff;
                                                        border-left: 4px solid #0074e8;
                                                        padding: 15px 20px;
                                                        margin: 25px 0;
                                                        border-radius: 4px;
                                                    }
                                                    .info-box p {
                                                        margin: 0;
                                                        font-size: 13px;
                                                        color: #666666;
                                                    }
                                                    .footer {
                                                        background: #f5f5f5;
                                                        padding: 25px 30px;
                                                        text-align: center;
                                                        border-top: 1px solid #e0e0e0;
                                                    }
                                                    .footer p {
                                                        color: #999999;
                                                        font-size: 12px;
                                                        margin: 5px 0;
                                                    }
                                                    .divider {
                                                        height: 1px;
                                                        background: #e0e0e0;
                                                        margin: 25px 0;
                                                    }
                                                </style>
                                            </head>
                                            <body>
                                                <div class="container">
                                                    <div class="header">
                                                        <h1>🔐 Recuperación de Contraseña</h1>
                                                    </div>
                                                    <div class="content">
                                                        <p>%s</p>
                                                        <p>Hemos recibido una solicitud para restablecer tu contraseña en <span class="highlight">EventvsMerida</span>.</p>
                                                        <div class="button-container">
                                                            <a href="%s" class="button" style="color: #ffffff !important; text-decoration: none !important;">Restablecer mi Contraseña</a>
                                                        </div>
                                                        <p style="text-align: center; color: #999999; font-size: 13px;">O copia y pega este enlace en tu navegador:</p>
                                                        <p style="text-align: center; word-break: break-all; background: #f8f9ff; padding: 12px; border-radius: 4px; font-size: 12px; color: #0074e8;">%s</p>
                                                        <p style="font-size: 13px;">Este enlace expirará en 30 minutos. Si no solicitaste restablecer tu contraseña, puedes ignorar este correo de forma segura.</p>
                                                    </div>
                                                    <div class="footer">
                                                        <p><strong>EventvsMerida</strong></p>
                                                        <p>Tu plataforma de eventos de Mérida</p>
                                                        <p style="margin-top: 10px; font-size: 11px;">© 2026 EventvsMerida. Todos los derechos reservados.</p>
                                                    </div>
                                                </div>
                                            </body>
                                        </html>
                                        """.formatted(saludo, urlRecuperacion, urlRecuperacion)
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