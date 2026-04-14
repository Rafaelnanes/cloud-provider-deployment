plugins {
    java
    id("org.springframework.boot") version "3.4.5"
    id("io.spring.dependency-management") version "1.1.7"
    id("com.google.cloud.tools.jib") version "3.4.5"
}

group = "com.example"
version = "0.0.2-SNAPSHOT-gsm"
description = "Products application"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("com.google.cloud:spring-cloud-gcp-starter-secretmanager:5.10.0")
    compileOnly("org.projectlombok:lombok")
    annotationProcessor("org.projectlombok:lombok")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

val gcpRegistry = "us-central1-docker.pkg.dev/project-3cec667f-8135-4778-9b4/docker-main"

jib {
    from { image = "eclipse-temurin:21-jre-jammy" }
    to {
        image = if (project.hasProperty("gcp")) "$gcpRegistry/products:${project.version}"
        else "products:${project.version}"
    }
    container {
        ports = listOf("8080")
        jvmFlags = listOf("-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0")
    }
}
