pluginManagement {
    // Read flutter.sdk from local.properties, or from FLUTTER_ROOT
    val propsFile = java.io.File(rootDir, "local.properties")
    val props = java.util.Properties()
    if (propsFile.exists()) {
        java.io.FileInputStream(propsFile).use { fis ->
            props.load(fis)
        }
    }

    val flutterSdk: String = props.getProperty("flutter.sdk")
        ?: System.getenv("FLUTTER_ROOT")
        ?: throw GradleException(
            "Flutter SDK not found. Set flutter.sdk in android/local.properties " +
            "or set the FLUTTER_ROOT environment variable."
        )

    // Point Gradle at Flutter’s plugin loader build
    includeBuild("$flutterSdk/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.6.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
    // Keep only if you actually use Google services (google-services.json present)
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
