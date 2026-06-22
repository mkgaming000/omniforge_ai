allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory
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

// ─── Kotlin 2.x compatibility shim ──────────────────────────────────────────
// Kotlin 2.0 dropped support for languageVersion / apiVersion 1.6 and 1.7.
// Several Flutter plugins (notably sentry_flutter 8.x) still declare
// languageVersion = "1.6" in their own build.gradle, causing:
//   e: Language version 1.6 is no longer supported; please, use version 1.8+
// We can't edit those third-party build files, but we CAN force every
// KotlinCompile task project-wide to use at least 1.9 if it tries to
// target a version Kotlin 2.x no longer accepts. Plugins that already
// target ≥1.8 are left untouched.
subprojects {
    afterEvaluate {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            val lv = kotlinOptions.languageVersion
            if (lv != null && lv < "1.8") {
                kotlinOptions.languageVersion = "1.9"
            }
            val av = kotlinOptions.apiVersion
            if (av != null && av < "1.8") {
                kotlinOptions.apiVersion = "1.9"
            }
        }
    }
}
// ─────────────────────────────────────────────────────────────────────────────

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
