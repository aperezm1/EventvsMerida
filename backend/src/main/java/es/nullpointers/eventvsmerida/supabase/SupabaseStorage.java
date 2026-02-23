package es.nullpointers.eventvsmerida.supabase;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.util.UriUtils;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Clase que se encarga de subir la imagen al bucket de Supabase una vez ha sido descargada con CURL.
 */
@Component
public class SupabaseStorage {

    private final String supabaseUrl;
    private final String key;

    private final String bucket = "imagenesEvento";

    private final RestClient supabaseClient;

    // Constructor que con @Value obtiene las propiedades del application.properties
    public SupabaseStorage(
            @Value("${supabase.url}") String supabaseUrl,
            @Value("${supabase.key}") String key
    ) {
        this.supabaseUrl = supabaseUrl;
        this.key = key;

        // Construye un RestClient para hacer la petición post.
        this.supabaseClient = RestClient.builder()
                .baseUrl(supabaseUrl)
                .defaultHeader("apikey", key)
                .defaultHeader("Authorization", "Bearer " + key)
                .build();
    }

    /**
     * Método que se encarga de subir la imagen a Supabase.
     * @param urlOrigen URL de la imagen que se desea almacenar.
     * @return URL de la imagen almacenadad en el bucket.
     */
    public String subirImagen(String urlOrigen) {
        // Descarga con curl.
        byte[] bytes = CurlDownloader.download(urlOrigen, Duration.ofSeconds(30));
        if (bytes.length == 0) {
            throw new IllegalStateException("La URL no devolvió contenido (body vacío): " + urlOrigen);
        }

        // Genera nombre de la imagen.
        String filename = filenameFromUrlOrGenerate(urlOrigen, null);
        String objectPath = filename; // raíz del bucket

        // Content-Type: se extrae según sea la extensión de la imagen.
        String contentType = contentTypeFromFilename(filename);

        // Normaliza la url del path para evitar caracteres raros.
        String encodedPath = UriUtils.encodePath(objectPath, StandardCharsets.UTF_8);

        // Petición POST para almacenar la imagen
        try {
            supabaseClient.post()
                    .uri(uriBuilder -> uriBuilder
                            .path("/storage/v1/object/{bucket}/{path}")
                            .queryParam("upsert", true)
                            .build(Map.of("bucket", bucket, "path", encodedPath)))
                    .contentType(MediaType.parseMediaType(contentType))
                    .body(bytes)
                    .retrieve()
                    .toBodilessEntity();
        } catch (HttpClientErrorException e) {
            String body = e.getResponseBodyAsString();
            boolean duplicate = body != null && body.contains("\"error\":\"Duplicate\"");
            if (duplicate) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Esta imagen ya está almacenada", e);
            }
            throw e;
        }

        return supabaseUrl + "/storage/v1/object/public/" + bucket + "/" + encodedPath;
    }

    /**
     * Méotodo para obtener el nombre del fichero o generar uno nuevo para evitar valores nulos.
     * @param sourceUrl URL de la imagen de origen.
     * @param mt Tipo de imagen.
     * @return Nombre de la imagen.
     */
    private static String filenameFromUrlOrGenerate(String sourceUrl, MediaType mt) {
        String path = URI.create(sourceUrl).getPath();
        String last = (path == null) ? "" : path.substring(path.lastIndexOf('/') + 1);

        if (last != null && !last.isBlank() && last.contains(".")) {
            return last;
        }

        String ext = extensionFromMediaType(mt);
        return "file-" + Instant.now().toEpochMilli() + "-" + UUID.randomUUID() + ext;
    }

    /**
     * Método que en función de como termine la extensión, sacamos el tipo de imagen
     * la cual se incluye en las cabeceras a la hora de subir la imagen para indicarle a Suoabase
     * el tipo de imagen.
     * @param filename Imagen.
     * @return Tipo de imagen.
     */
    private static String contentTypeFromFilename(String filename) {
        String f = filename.toLowerCase();
        if (f.endsWith(".png")) return "image/png";
        if (f.endsWith(".jpg") || f.endsWith(".jpeg")) return "image/jpeg";
        return "application/octet-stream";
    }

    /**
     * Método que devuelve la extensión del fichero en función del tipo de imagen.
     * @param mt Tipo de imagen.
     * @return Extensión que va a utilizar la imagen.
     */
    private static String extensionFromMediaType(MediaType mt) {
        if (mt == null) return "";
        if (MediaType.IMAGE_PNG.includes(mt)) return ".png";
        if (MediaType.IMAGE_JPEG.includes(mt)) return ".jpg";
        return "";
    }
}