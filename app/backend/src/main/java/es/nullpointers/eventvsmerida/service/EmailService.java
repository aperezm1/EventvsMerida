package es.nullpointers.eventvsmerida.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Servicio encargado de enviar correos electrónicos relacionados con la recuperación de contraseña.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
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
                "Hola " + nombre + ",\n\n"
                        + "Puedes restablecer tu contraseña accediendo al siguiente enlace:\n\n"
                        + enlace + "\n\n"
                        + "Este enlace expirará en 30 minutos.\n\n"
                        + "Si no has solicitado restablecer tu contraseña, ignora este correo. No se realizará ningún cambio en tu cuenta.\n\n"
                        + "Un saludo,\n"
                        + "El equipo de Eventvs Mérida 👋"
        );

        mailSender.send(mensaje);
    }
}