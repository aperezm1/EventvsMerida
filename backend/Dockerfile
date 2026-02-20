# Build stage (Maven + JDK 25 Temurin)
FROM maven:3.9.12-eclipse-temurin-25 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage (Java 25)
FROM eclipse-temurin:25-jre
COPY --from=build /app/target/EventvsMerida-0.0.1.jar /app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]