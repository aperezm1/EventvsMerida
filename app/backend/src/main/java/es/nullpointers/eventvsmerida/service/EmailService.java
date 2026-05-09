package es.nullpointers.eventvsmerida.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    public void enviarCorreoRecuperacion(
            String destino,
            String token,
            String nombre) {

        String enlace =
                "http://127.0.0.1:5501/index.html?token="
                        + token;

        SimpleMailMessage mensaje =
                new SimpleMailMessage();

        mensaje.setTo(destino);

        mensaje.setSubject(
                "Recuperación de contraseña - Eventvs Mérida"
        );

        mensaje.setText(
                "Hola" + nombre +", haz click en el siguiente enlace para restablecer tu contraseña:\n\n"
                        + enlace
                        + "\n\nEste enlace expira en 15 minutos."
        );

        mailSender.send(mensaje);
    }
}