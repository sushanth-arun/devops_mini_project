# ==============================================================================
# Stage 1: Build & Package (eclipse-temurin:17-jdk with Maven wrapper)
# ==============================================================================
FROM eclipse-temurin:17-jdk AS builder
WORKDIR /workspace

# Copy Maven wrapper & project definition for dependency caching
COPY mvnw pom.xml ./
COPY .mvn/ .mvn/

# Ensure execution permissions on the Maven wrapper
RUN chmod +x ./mvnw

# Pre-fetch project dependencies to leverage Docker layer caching
RUN ./mvnw dependency:go-offline -B || true

# Copy application source code
COPY src/ src/

# Build executable Spring Boot JAR (tests verified during CI stage)
RUN ./mvnw clean package -DskipTests

# ==============================================================================
# Stage 2: Minimal Runtime Environment (eclipse-temurin:17-jre-alpine)
# ==============================================================================
FROM eclipse-temurin:17-jre-alpine
LABEL maintainer="PSG iTech - DevOps Mini-Project Team" \
      project="Healthcare Clinic Management System" \
      course="Anna University 5th Sem - DevOps Lab" \
      version="1.0.0"

WORKDIR /app

# Security Hardening: Create non-root system group and user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy compiled JAR from Stage 1 builder
COPY --from=builder /workspace/target/*.jar app.jar

# Enforce non-root ownership on application files
RUN chown -R appuser:appgroup /app

# Switch to unprivileged runtime user
USER appuser

# Expose Spring Boot web service port
EXPOSE 8080

# Container-aware JVM memory optimization
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Container health probe
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Launch application with exec to allow proper Unix signal propagation (SIGTERM/SIGINT)
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
