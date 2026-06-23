import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// The Google Services plugin hard-fails the build if google-services.json
// is missing, which would make Firebase a brand-new build-blocker on any
// fresh checkout. Applying it only when the file exists means: no file ->
// build succeeds, Firebase.initializeApp() fails gracefully at runtime
// (see lib/main.dart); real file -> Crashlytics wires up normally. Get
// your own google-services.json from https://console.firebase.google.com
// and drop it in this directory (android/app/) to enable it.
val firebaseConfigured = file("google-services.json").exists()
if (firebaseConfigured) {
    apply(plugin = "com.google.gms.google-services")
    // Required alongside google-services for Crashlytics specifically —
    // without it the app crashes immediately at startup with "Crashlytics
    // build ID is missing" (per Firebase's own docs).
    apply(plugin = "com.google.firebase.crashlytics")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    FileInputStream(localPropertiesFile).use { stream ->
        localProperties.load(stream)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0.0"

// Release signing is sourced from android/key.properties, which is generated
// at CI time (see .github/workflows/build-apk.yml / build-aab.yml) and is
// git-ignored locally. If it's absent, the release build type silently
// falls back to the debug signing config so `flutter build` still succeeds
// on a fresh checkout.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

android {
    namespace = "com.omniforge.ai"
    // flutter_secure_storage 10.x and flutter_tts 4.x both require compileSdk 36.
    // (flutter_plugin_android_lifecycle requires 35.)
    // minSdk raised to 24 to satisfy flutter_tts 4.x manifest requirement.
    compileSdk = 36
    ndkVersion = "26.1.10909125"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    // AGP 8.6.0's `android.kotlinOptions` (com.android.build.api.dsl.KotlinJvmOptions)
    // is completely separate from KGP's removed task-level KotlinJvmOptions.
    // android.compilerOptions does NOT exist in AGP 8.6.0 for com.android.application
    // (only available in AGP 8.7+ / KMP). Using kotlinOptions here is correct.
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.omniforge.ai"
        // flutter_tts 4.x requires minSdk 24 (declared in its AndroidManifest.xml).
        // Raised from 23 → 24 to fix: "minSdkVersion 23 cannot be smaller than
        // version 24 declared in library [:flutter_tts]" manifest merger error.
        // All other plugins require minSdk ≤ 23, so 24 is fully compatible.
        minSdk = 24
        targetSdk = 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (hasKeystoreProperties) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystoreProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }

    flavorDimensions += "default"
    productFlavors {
        create("production") {
            dimension = "default"
            applicationIdSuffix = ""
        }
        create("staging") {
            dimension = "default"
            applicationIdSuffix = ".staging"
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
        resources {
            excludes += setOf(
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "META-INF/*.kotlin_module",
                "META-INF/DEPENDENCIES"
            )
        }
    }

    bundle {
        language {
            enableSplit = false
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
        disable += setOf("MissingTranslation", "ExtraTranslation")
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.window:window:1.3.0")
    implementation("androidx.window:window-java:1.3.0")
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    implementation("androidx.biometric:biometric:1.2.0-alpha05")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:33.4.0"))
    implementation("com.google.firebase:firebase-crashlytics")
}
