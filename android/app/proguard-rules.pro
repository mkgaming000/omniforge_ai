# Keep Flutter and OmniForge classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class com.omniforge.ai.** { *; }

# Bouncy Castle (encryption)
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**
-dontwarn javax.naming.**

# Retrofit / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Hive (pure-Dart local DB — no Java/Kotlin-side classes to keep)

# ─── Google Play Core (split-install / deferred components) ──────────────────
# Flutter's PlayStoreDeferredComponentManager and FlutterPlayStoreSplitApplication
# reference Play Core split-install classes at the bytecode level, but these
# classes are only present at runtime when the app is distributed via the Play
# Store with deferred components enabled. R8 fails with "Missing class" errors
# in a standard release build because the play.core artifact is not a compile-
# time dependency of the Flutter engine embedding. Suppress with -dontwarn so
# R8 treats them as optional (which they are for a standard non-deferred build).
-dontwarn com.google.android.play.core.**
# ─────────────────────────────────────────────────────────────────────────────

# ─── ML Kit optional script recognizers ─────────────────────────────────────
# google_mlkit_text_recognition includes references to all language-specific
# recognizer option classes (Chinese, Devanagari, Japanese, Korean) even though
# only the Latin recognizer is bundled by default. The additional language model
# packages are optional runtime downloads. Suppress the R8 "Missing class"
# errors for the non-bundled script recognizer options.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
# ─────────────────────────────────────────────────────────────────────────────
