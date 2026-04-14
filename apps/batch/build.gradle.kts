plugins {
	java
	id("org.springframework.boot") version "4.0.3"
	id("io.spring.dependency-management") version "1.1.7"
	id("com.google.cloud.tools.jib") version "3.4.5"
}

group = "com.example"
version = "0.0.1-SNAPSHOT"
description = "Batch application"

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
	compileOnly("org.projectlombok:lombok")
	annotationProcessor("org.projectlombok:lombok")
	testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

val gcpRegistry = "us-central1-docker.pkg.dev/project-3cec667f-8135-4778-9b4/docker-main"

jib {
	from { image = "eclipse-temurin:21-jre-alpine" }
	to {
		image = if (project.hasProperty("gcp")) "$gcpRegistry/batch:${project.version}"
		        else "batch:${project.version}"
	}
	container {
		jvmFlags = listOf("-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0")
	}
}
