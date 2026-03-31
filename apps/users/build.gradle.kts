plugins {
	java
	id("org.springframework.boot") version "4.0.3"
	id("io.spring.dependency-management") version "1.1.7"
	id("com.google.cloud.tools.jib") version "3.4.5"
}

group = "com.example"
version = "0.0.1-SNAPSHOT"
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
	compileOnly("org.projectlombok:lombok")
	annotationProcessor("org.projectlombok:lombok")
	testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

jib {
	from { image = "eclipse-temurin:21-jre-alpine" }
	to { image = "users:jvm" }
	container {
		ports = listOf("8080")
		jvmFlags = listOf("-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0")
	}
}
