// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")        // keep if your MainActivity is Kotlin
    id("com.google.gms.google-services")      // Firebase
}

android {
    namespace = "com.example.tamil_quiz_app"  // <— change to your package
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.tamil_quiz_app"   // <— must match google-services.json
        minSdk = 23                                     // Firebase requires 23+
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Java/Kotlin toolchains
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    // packaging tweaks (common with Firebase)
    packaging {
        resources {
            excludes += setOf("/META-INF/{AL2.0,LGPL2.1}")
        }
    }
}

// Tell the Flutter Gradle plugin where the Flutter project root is
flutter {
    // path from android/ to your Flutter project root
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    // (Other dependencies are pulled in by Flutter + Firebase plugins)
}
