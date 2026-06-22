pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        requireNotNull(flutterSdkPath) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.6.0" apply false
    // flutter_tts 4.x depends on kotlin-stdlib 2.2.20 (binary metadata v2.2.0).
    // Kotlin 1.9.x can only read metadata up to 2.0.0, causing hundreds of
    // "Incompatible version of Kotlin" compile errors at :flutter_tts:compileReleaseKotlin.
    // Kotlin 2.2.20 matches the stdlib version and is backward-compatible with
    // AGP 8.6.0 + Gradle 8.7.
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
}

include(":app")
