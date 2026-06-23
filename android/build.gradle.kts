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
//
// Kotlin 2.2.x also removed the old `kotlinOptions` accessor entirely (it is
// now a hard error, not a warning). The replacement is `compilerOptions`,
// which uses Property<KotlinVersion> (an enum) instead of plain strings.
//
// NOTE: Do NOT wrap this in afterEvaluate { }.  Gradle 8.7 throws
// "Cannot run afterEvaluate when the project is already evaluated" because
// `evaluationDependsOn(":app")` above forces :app to finish first.
// `configureEach` is inherently lazy — it fires at task-creation time, not
// after project evaluation — so no afterEvaluate wrapper is needed.
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            val minOrd = org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8.ordinal
            val target  = org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_9

            val lv = languageVersion.orNull
            if (lv != null && lv.ordinal < minOrd) {
                languageVersion.set(target)
            }

            val av = apiVersion.orNull
            if (av != null && av.ordinal < minOrd) {
                apiVersion.set(target)
            }
        }
    }
}
// ─────────────────────────────────────────────────────────────────────────────

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
