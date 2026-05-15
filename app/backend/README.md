# Eventvs Mérida — Backend (Spring Boot)

Backend REST para la plataforma Eventvs Mérida.

## 🚀 Instalación y arranque

### Requisitos
- JDK 25
- Maven
- Docker (opcional)

### Pasos

```bash
# 1. Compilar
./mvnw clean package

# 2. Ejecutar en desarrollo
./mvnw spring-boot:run

# Windows
.\mvnw.cmd spring-boot:run

# 3. Ejecutable JAR
java -jar target/EventvsMerida-1.0.0.jar
```

La aplicación se expone por defecto en `http://localhost:8080`.

## 📁 Estructura del proyecto

```
application.properties     # fichero de configuración (raíz del proyecto, junto a pom.xml)
src/
├── main/
│   ├── java/
│   │   └── es/nullpointers/eventvsmerida/
│   │       ├── controller/        # Endpoints REST (usuarios, eventos, categorías, roles, auth)
│   │       ├── service/           # Lógica de negocio
│   │       ├── repository/        # Repositorios JPA
│   │       ├── entity/            # Entidades JPA
│   │       ├── dto/               # DTOs request/response
│   │       ├── mapper/            # Conversores entidad <-> DTO
│   │       ├── security/          # Configuración de seguridad
│   │       ├── supabase/          # Integración con Supabase Storage
│   │       └── utils/             # Utilidades y validaciones
│   └── resources/
```

## ✨ Características

- Endpoints REST para gestión de usuarios, roles, eventos y categorías (`controller/`).
- Autenticación y gestión de tokens (endpoints en `AuthController`; se gestionan `RefreshToken` y `PasswordResetToken`).
- Integración con Supabase Storage para subida/obtención/eliminación de imágenes (`supabase/SupabaseStorage.java`).
- Documentación OpenAPI disponible mediante `springdoc` (dependencia presente en `pom.xml`).
- Carpeta `security/`: agrupa la configuración y componentes de autenticación y autorización (p. ej. `SecurityConfig`, `CustomUserDetailsService`, `CorsConfig`); las rutas sensibles están protegidas mediante control de acceso por **rol** (p. ej. **Administrador**, **Organizador**) y el proyecto utiliza refresh tokens y `BCryptPasswordEncoder` para gestionar sesiones y contraseñas.

## 🛠 Tecnologías

- Spring Boot `4.0.3`
- Spring Web, Spring Data JPA, Spring Security
- PostgreSQL driver
- Lombok (scope `provided`)
- springdoc-openapi (UI para la documentación)

## 🔧 Configuración

- El archivo `application.properties` debe ubicarse en la raíz del proyecto (junto a `pom.xml`) y contener al menos las propiedades que se indican a continuación para que la aplicación funcione correctamente.

```properties
spring.datasource.url=jdbc:postgresql://<HOST>:<PORT>/<DB>
spring.datasource.username=<DB_USERNAME>
spring.datasource.password=<DB_PASSWORD>
spring.datasource.driver-class-name=org.postgresql.Driver
spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect

supabase.url=https://<PROJECT>.supabase.co
supabase.key=<SUPABASE_KEY>

server.servlet.session.cookie.same-site=None
server.servlet.session.cookie.secure=true
server.servlet.session.timeout=2h
server.servlet.session.cookie.max-age=2h

mailjet.api-key=<MAILJET_API_KEY>
mailjet.secret-key=<MAILJET_SECRET_KEY>
mailjet.from-email=<FROM_EMAIL>
mailjet.from-name=<NAME>
app.recover-url=https://<YOUR_RECOVER_URL>
```

## 🐳 Docker y despliegue

Se utiliza el `Dockerfile` incluido para construir la imagen y desplegar en Render. Las variables definidas en `application.properties` deben configurarse como variables de entorno en la plataforma Render.

```bash
docker build -t eventvs-backend .
```

## 🔗 Enlaces

- Repositorio: https://github.com/Null-Pointers-Albarregas/EventvsMerida

---

Desarrollado por **Adrián Pérez Morales**, **David Muñoz Collado** y **Eva Retamar Muñoz**  
IES Albarregas · Mérida, Extremadura
