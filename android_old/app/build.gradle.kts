android {
    // ... your existing compileSdk, defaultConfig, etc.

    buildTypes {
        debug {
            // Never shrink in debug
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            // Either disable both:
            // isMinifyEnabled = false
            // isShrinkResources = false

            // or enable BOTH if you want shrinking:
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // You can use your real signing config here; debug is fine for now:
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
