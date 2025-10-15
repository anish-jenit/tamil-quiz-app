// android/settings.gradle.kts

import java.io.File
import java.util.Properties

// Read flutter.sdk from local.properties
val localProps = Properties().apply {
    val f = File(rootDir, "local.properties")
    if (f.exists()) f.inputStream().use { this.load(it) }
}
val flutterSdk = localProps.getProperty("flutter.sdk")
    ?: throw GradleException("flutter.sdk not set in local.properties")

pluginManagement {
    // Load Flutter’s Gradle plugin from the Flutter SDK
    includeBuild("$flutterSdk/packages/flutter_tools/gradle")

    // Include generated plugin builds ONLY if they exist (created after `flutter pub get`)
    val pluginsDir = File(rootDir, "../.dart_tool/flutter/build_plugins")
    if (pluginsDir.exists()) includeBuild(pluginsDir)

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

include(":app")
