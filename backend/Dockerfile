FROM maven:3.9.6-eclipse-temurin-25 AS build
WORKDIR /app
COPY pom.xml .
COPY src src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:25-jre
COPY --from=build /app/target/EventvsMerida-0.0.1.jar app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]