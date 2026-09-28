allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// NOTE: the old blanket JVM-17 forcing block was removed — Gradle 9.1's
// stricter Kotlin DSL rejects the star-projected CommonExtension.apply{}
// pattern, and the upstream toolchain (AGP 9.0.1 + Gradle 9.1 +
// kotlin.jvm.target.validation.mode=warning) no longer needs it.

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Firebase
plugins {
  // ...

  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.5.0" apply false

}
